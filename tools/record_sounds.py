"""Local page for recording the six letter sounds with this computer's microphone.

Run:  python3 tools/record_sounds.py   then open http://localhost:8765 in Firefox.
Each take is saved as recorded/<id>.<ext> (the browser's own format) and converted to
recorded/<id>.wav: mono, 48 kHz, leading/trailing silence trimmed, -18 LUFS.
"""

import json
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "recorded"
PORT = 8765

TAKES = [
    {"id": f"lyd_{k}{suffix}", "letter": k, "held": held}
    for held, suffix in ((False, ""), (True, "_held"))
    for k in "asilom"
]
GUIDE = {
    "a": ("a som i ape", "Munnen åpen. Bare lyden, ikke et ord."),
    "s": ("s som i sol", "Hvesing som en slange. Ikke «ess»."),
    "i": ("i som i is", "Smil bredt. Ikke «ei»."),
    "l": ("l som i lam", "Tunga bak tennene. Ikke «ell»."),
    "o": ("o som i ost (lyden u)", "Runde lepper. Lyden er u, som i ost."),
    "m": ("m som i mus", "Leppene lukket, nynn. Ikke «em»."),
}


def process(raw: Path, wav: Path) -> dict:
    trim = (
        "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.03,"
        "areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,areverse,"
        "loudnorm=I=-18:TP=-1:LRA=7"
    )
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-loglevel",
            "error",
            "-i",
            str(raw),
            "-af",
            trim,
            "-ac",
            "1",
            "-ar",
            "48000",
            str(wav),
        ],
        check=True,
    )
    dur = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(wav)],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    return {"seconds": round(float(dur), 2)}


class Handler(BaseHTTPRequestHandler):
    def _send(self, code: int, body: bytes, ctype: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if self.path == "/":
            takes = [
                {
                    **t,
                    "word": GUIDE[t["letter"]][0],
                    "tip": GUIDE[t["letter"]][1],
                    "saved": (OUT / f"{t['id']}.wav").exists(),
                }
                for t in TAKES
            ]
            self._send(
                200,
                PAGE.replace("__TAKES__", json.dumps(takes, ensure_ascii=False)).encode(),
                "text/html; charset=utf-8",
            )
        elif self.path.startswith("/wav/"):
            f = OUT / (Path(self.path.split("?")[0]).name + ".wav")
            if f.exists():
                self._send(200, f.read_bytes(), "audio/wav")
            else:
                self._send(404, b"", "text/plain")
        else:
            self._send(404, b"", "text/plain")

    def do_POST(self) -> None:
        tid = Path(self.path).name
        if tid not in {t["id"] for t in TAKES}:
            self._send(400, b"unknown id", "text/plain")
            return
        data = self.rfile.read(int(self.headers["Content-Length"]))
        ext = "ogg" if "ogg" in self.headers.get("Content-Type", "") else "webm"
        OUT.mkdir(exist_ok=True)
        raw = OUT / f"{tid}.{ext}"
        raw.write_bytes(data)
        try:
            info = process(raw, OUT / f"{tid}.wav")
        except subprocess.CalledProcessError as exc:
            self._send(500, f"ffmpeg failed: {exc}".encode(), "text/plain")
            return
        self._send(200, json.dumps(info).encode(), "application/json")

    def log_message(self, *args: object) -> None:
        pass


PAGE = """<!doctype html><html lang="nb"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>MWM Les lydopptak</title>
<style>
:root{--bg:#f3f6f5;--panel:#fff;--fg:#17312e;--muted:#5b726e;--line:#d5e0dd;--accent:#0f7c72;--rec:#c0392b;--ok:#e3efe9}
body{background:var(--bg);color:var(--fg);font:17px/1.5 system-ui,sans-serif;margin:0;padding:24px 16px 64px}
main{max-width:720px;margin:0 auto;display:grid;gap:20px}
h1{margin:0;font-size:1.8rem} h2{margin:0;font-size:1.2rem}
p{margin:0;color:var(--muted)}
.take{display:grid;grid-template-columns:auto 1fr auto;gap:6px 16px;align-items:center;background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:14px}
.take.saved{background:var(--ok)}
.big{font-size:2.6rem;font-weight:700;width:2.2ch;text-align:center}
.info{min-width:0} .info b{display:block}
.btns{display:flex;gap:8px;flex-wrap:wrap;justify-content:flex-end}
button{font:600 1rem system-ui;padding:10px 16px;border-radius:6px;border:1px solid var(--accent);background:var(--accent);color:#fff;cursor:pointer}
button.play{background:transparent;color:var(--accent)}
button.on{background:var(--rec);border-color:var(--rec)}
.state{grid-column:2/4;font-size:.9rem;color:var(--muted)}
.meter{grid-column:1/4;height:10px;background:var(--line);border-radius:5px;overflow:hidden}
.meter i{display:block;height:100%;width:0;background:var(--accent)}
</style></head><body><main>
<h1>MWM Les: lydopptak</h1>
<p>Seks lyder, hver to ganger: kort (cirka et halvt sekund) og lang (hold lyden jevnt i cirka to sekunder).
Si bare lyden, aldri bokstavnavnet. Trykk Ta opp, si lyden, trykk Stopp. Hør på opptaket, og ta det på nytt hvis det ikke er riktig.</p>
<p>Stille rom, 20 til 30 cm fra mikrofonen.</p>
<section><h2>Korte lyder</h2></section><div id="short" style="display:grid;gap:10px"></div>
<section><h2>Lange lyder (hold i cirka 2 sekunder)</h2></section><div id="held" style="display:grid;gap:10px"></div>
</main><script>
const TAKES=__TAKES__;let rec=null,chunks=[],active=null;
function row(t){
 const d=document.createElement("div");d.className="take"+(t.saved?" saved":"");
 d.innerHTML=`<span class="big">${t.letter}</span><span class="info"><b>${t.word}${t.held?" (lang)":" (kort)"}</b>${t.tip}</span>
 <span class="btns"><button class="rec">Ta opp</button><button class="play">Hør</button></span><span class="state">${t.saved?"Lagret":"Ikke tatt opp ennå"}</span>`;
 const b=d.querySelector(".rec"),p=d.querySelector(".play"),s=d.querySelector(".state");
 p.onclick=()=>{const a=new Audio("/wav/"+t.id+"?"+Date.now());s.textContent="Spiller av ...";
  a.onended=()=>s.textContent="Ferdig avspilt";a.onerror=()=>s.textContent="Fant ikke opptaket. Ta opp på nytt.";
  a.play().catch(e=>s.textContent="Kunne ikke spille av: "+e.message)};
 b.onclick=async()=>{
  if(active===t.id){rec.stop();return}
  if(active){s.textContent="Stopp det andre opptaket først";return}
  let stream;try{stream=await navigator.mediaDevices.getUserMedia({audio:{echoCancellation:false,noiseSuppression:false,autoGainControl:false}})}
  catch(e){s.textContent="Fikk ikke tilgang til mikrofonen: "+e.message;return}
  chunks=[];rec=new MediaRecorder(stream);active=t.id;b.textContent="Stopp";b.classList.add("on");
  s.textContent="Tar opp fra: "+(stream.getAudioTracks()[0].label||"ukjent mikrofon");
  const m=document.createElement("span");m.className="meter";m.innerHTML="<i></i>";d.append(m);
  const ac=new AudioContext(),an=ac.createAnalyser();ac.createMediaStreamSource(stream).connect(an);
  const buf=new Float32Array(an.fftSize);(function tick(){if(active!==t.id){ac.close();m.remove();return}
   an.getFloatTimeDomainData(buf);let pk=0;for(const v of buf)pk=Math.max(pk,Math.abs(v));
   m.firstChild.style.width=Math.min(100,pk*100)+"%";requestAnimationFrame(tick)})();
  rec.ondataavailable=e=>chunks.push(e.data);
  rec.onstop=async()=>{stream.getTracks().forEach(x=>x.stop());active=null;b.textContent="Ta opp";b.classList.remove("on");
   const blob=new Blob(chunks,{type:rec.mimeType});s.textContent="Lagrer ...";
   const r=await fetch("/save/"+t.id,{method:"POST",headers:{"Content-Type":rec.mimeType},body:blob});
   if(!r.ok){s.textContent="Lagring feilet: "+await r.text();return}
   const j=await r.json();d.classList.add("saved");s.textContent=`Lagret, ${j.seconds} s etter trimming. Trykk Hør for å sjekke.`+(j.seconds<0.15?" (for kort, ta på nytt)":"")};
  rec.start()};
 return d}
for(const t of TAKES)document.getElementById(t.held?"held":"short").append(row(t));
</script></body></html>"""

if __name__ == "__main__":
    print(f"Open http://localhost:{PORT} in your browser. Takes go to {OUT}")
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
