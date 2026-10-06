"""Local page for recording the letter sounds, letter names and Pip's lines with this computer's microphone.

Run:  python3 tools/record_sounds.py   then open http://localhost:8765 in Firefox.
Each take is saved as recorded/<id>.<ext> (the browser's own format) and converted to
recorded/<id>.wav: mono, 48 kHz, leading/trailing silence trimmed, -18 LUFS.
"""

import json
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote

OUT = Path(__file__).resolve().parents[1] / "recorded"
PORT = 8765

NAMES = {
    "a": "a", "s": "ess", "i": "i", "l": "ell", "o": "o", "m": "em",
    "e": "e", "t": "te", "b": "be", "å": "å",
}
LETTERS = "asilometbå"
STOPS = "tb"  # t and b cannot be held: they get a short take only
TAKES = [
    {"id": f"lyd_{k}{suffix}", "letter": k, "held": held, "name": False}
    for held, suffix in ((False, ""), (True, "_held"))
    for k in LETTERS
    if not (held and k in STOPS)
] + [{"id": f"navn_{k}", "letter": k, "held": False, "name": True} for k in LETTERS]
GUIDE = {
    "a": ("a som i ape", "Munnen åpen. Bare lyden, ikke et ord."),
    "s": ("s som i sol", "Hvesing som en slange. Ikke «ess»."),
    "i": ("i som i is", "Smil bredt. Ikke «ei»."),
    "l": ("l som i lam", "Tunga bak tennene. Ikke «ell»."),
    "o": ("o som i ost (lyden u)", "Runde lepper. Lyden er u, som i ost."),
    "m": ("m som i mus", "Leppene lukket, nynn. Ikke «em»."),
    "e": ("e som i sel", "Lang e, smil litt. Ikke «ei»."),
    "t": ("t som i mat", "Kort pust med tunga bak tennene. Ikke «te»."),
    "b": ("b som i båt", "Kort, leppene spretter opp. Ikke «be»."),
    "å": ("å som i båt", "Runde lepper, lang lyd."),
}

# Pip's lines. Draft wording; the owner edits the text on the page, edits go to recorded/script.json.
LINES = [
    ("Start", "op_1", "Hei! Jeg heter Pip."),
    ("Start", "op_2", "Ser du lammet på den lille øya der borte? Det er bestevennen min."),
    ("Start", "op_3", "Lammet kan ikke svømme. Derfor vil jeg bygge en bro."),
    ("Start", "op_4", "Broa skal vi lage av bokstaver."),
    ("Start", "op_5", "Vil du hjelpe meg? Trykk på meg!"),
    ("Start", "levels_intro", "Seks ord skal vi bygge. Hvert ord gjør broa lengre."),
    ("Historie", "lamb_baa", "Bææ!"),
    ("Historie", "mid_sol", "Sola varmer. Da er det lett å bygge!"),
    ("Historie", "mid_sel", "Selen dykker under broa. Plask!"),
    ("Historie", "mid_les", "Jeg tar med boka. Vi kan lese for lammet når broa er ferdig."),
    ("Historie", "mid_mat", "Lammet er så sultent. Vi må gi det mat!"),
    ("Historie", "mid_baat", "Båten kommer nærmere. Se, den har seil!"),
    ("Historie", "final_party", "Lammet er her! Nå kan vi leke sammen hver dag."),
    ("Øya", "hub_find", "Først må vi finne bokstavene. Bli med!"),
    ("Øya", "hub_write", "Nå skal vi skrive bokstavene i sanden."),
    ("Øya", "hub_bridge", "Nå kan vi bygge broa. Kom!"),
    ("Øya", "hub_back", "Hei igjen! Lammet venter på oss."),
    ("Øya", "hub_idle", "Trykk der det lyser."),
    ("Ny bokstav", "intro_a", "Denne bokstaven heter a. Den sier aaa."),
    ("Ny bokstav", "intro_s", "Denne bokstaven heter ess. Den sier sss."),
    ("Ny bokstav", "intro_i", "Denne bokstaven heter i. Den sier iii."),
    ("Ny bokstav", "intro_l", "Denne bokstaven heter ell. Den sier lll."),
    ("Ny bokstav", "intro_o", "Denne bokstaven heter o. Den sier uuu, som i ost."),
    ("Ny bokstav", "intro_m", "Denne bokstaven heter em. Den sier mmm."),
    ("Ny bokstav", "intro_e", "Denne bokstaven heter e. Den sier eee."),
    ("Ny bokstav", "intro_t", "Denne bokstaven heter te. Den sier t."),
    ("Ny bokstav", "intro_b", "Denne bokstaven heter be. Den sier b."),
    ("Ny bokstav", "intro_å", "Denne bokstaven heter å. Den sier ååå."),
    ("Ny bokstav", "intro_again", "Hør en gang til."),
    ("Finn bokstaven", "find_in", "Her i sanden ligger det bokstaver. Hør godt etter!"),
    ("Finn bokstaven", "find_ask", "Hvilken bokstav sier dette?"),
    ("Finn bokstaven", "find_right", "Ja! Den fant du."),
    ("Finn bokstaven", "find_wrong", "Den sier noe annet. Hør en gang til."),
    ("Finn bokstaven", "find_done", "Nå har vi funnet nok bokstaver. Bra jobba!"),
    ("Skriv i sanden", "write_in", "Nå skal du skrive i sanden. Se på meg først."),
    ("Skriv i sanden", "write_turn", "Nå er det din tur. Skriv med fingeren."),
    ("Skriv i sanden", "write_retry", "Nesten! Prøv en gang til."),
    ("Skriv i sanden", "write_right", "Så fint! Den blir en stein til broa."),
    ("Skriv i sanden", "write_again", "Skriv den en gang til."),
    ("Skriv i sanden", "write_next", "Nå skriver vi en bokstav til."),
    ("Skriv i sanden", "write_show_again", "Se på meg en gang til."),
    ("Skriv i sanden", "write_trace", "Nå følger du stripene med fingeren."),
    ("Skriv i sanden", "write_alone", "Nå skriver du helt selv."),
    ("Skriv i sanden", "write_done", "Nå har vi nok steiner. Vi tar dem med til broa."),
    ("Broa", "bridge_in", "Nå bygger vi broa. Hver stein er en bokstav."),
    ("Broa", "bridge_word_lam", "Vi skal skrive lam. Hør: lll, aaa, mmm. Lam!"),
    ("Ord", "hook_sol", "Se, sola skinner!"),
    ("Ord", "bridge_word_sol", "Vi skal skrive sol. Hør: sss, ooo, lll. Sol!"),
    ("Ord", "hook_sel", "Se! En sel svømmer i vannet."),
    ("Ord", "bridge_word_sel", "Vi skal skrive sel. Hør: sss, eee, lll. Sel!"),
    ("Ord", "hook_båt", "Se der! En båt på sjøen."),
    ("Ord", "bridge_word_båt", "Vi skal skrive båt. Hør: b, ååå, t. Båt!"),
    ("Ord", "hook_mat", "Lammet er sultent. Det trenger mat."),
    ("Ord", "bridge_word_mat", "Vi skal skrive mat. Hør: mmm, aaa, t. Mat!"),
    ("Ord", "hook_les", "Jeg har en bok. Jeg liker å lese."),
    ("Ord", "bridge_word_les", "Vi skal skrive les. Hør: lll, eee, sss. Les!"),
    ("Ord", "hook_lam", "Og så det viktigste ordet. Det er lammet sitt ord!"),
    ("Ord ferdig", "done_sol", "Sola skinner på broa. Nå blir det varmt og godt!"),
    ("Ord ferdig", "done_sel", "Selen klapper med luffene. Den vil se broa bli ferdig."),
    ("Ord ferdig", "done_baat", "Båten tuter: tuut! Den seiler forbi broa vår."),
    ("Ord ferdig", "done_mat", "Nå har lammet fått mat. Nam nam!"),
    ("Ord ferdig", "done_les", "Jeg leser ordene på broa for lammet. Det liker lammet!"),
    ("Nivå", "level_next", "Hurra! Nå går vi videre til neste ord."),
    ("Nivå", "level_back", "Hei igjen! Vi fortsetter der vi slapp."),
    ("Broa", "bridge_word_done", "Ja! Der står det et ord."),
    ("Broa", "bridge_next", "Broa er ikke lang nok ennå. Vi lager ett ord til!"),
    ("Broa", "bridge_ask", "Hvilken bokstav mangler?"),
    ("Broa", "bridge_right", "Ja! Der passet den."),
    ("Broa", "bridge_done", "Broa er ferdig! Der står det lam."),
    ("Broa", "bridge_walk", "Se, lammet kommer over broa! Takk for hjelpen!"),
    ("Slutt", "end_bye", "Nå er jeg trøtt. Takk for i dag, ha det!"),
]
SCRIPT = OUT / "script.json"


def script_text() -> dict:
    edits = json.loads(SCRIPT.read_text()) if SCRIPT.exists() else {}
    return {lid: edits.get(lid, text) for _, lid, text in LINES}


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
                    "word": f"Bokstavnavnet «{NAMES[t['letter']]}»"
                    if t["name"]
                    else GUIDE[t["letter"]][0],
                    "tip": "Si navnet på bokstaven, tydelig, en gang."
                    if t["name"]
                    else GUIDE[t["letter"]][1],
                    "saved": (OUT / f"{t['id']}.wav").exists(),
                }
                for t in TAKES
            ]
            texts = script_text()
            takes += [
                {
                    "id": lid,
                    "scene": scene,
                    "line": texts[lid],
                    "saved": (OUT / f"{lid}.wav").exists(),
                }
                for scene, lid, _ in LINES
            ]
            self._send(
                200,
                PAGE.replace("__TAKES__", json.dumps(takes, ensure_ascii=False)).encode(),
                "text/html; charset=utf-8",
            )
        elif self.path.startswith("/wav/"):
            f = OUT / (Path(unquote(self.path.split("?")[0])).name + ".wav")
            if f.exists():
                self._send(200, f.read_bytes(), "audio/wav")
            else:
                self._send(404, b"", "text/plain")
        else:
            self._send(404, b"", "text/plain")

    def do_POST(self) -> None:
        tid = Path(unquote(self.path)).name
        if self.path.startswith("/text/") and tid in {lid for _, lid, _ in LINES}:
            OUT.mkdir(exist_ok=True)
            edits = json.loads(SCRIPT.read_text()) if SCRIPT.exists() else {}
            edits[tid] = self.rfile.read(int(self.headers["Content-Length"])).decode().strip()
            SCRIPT.write_text(json.dumps(edits, ensure_ascii=False, indent=1))
            self._send(200, b"ok", "text/plain")
            return
        if tid not in {t["id"] for t in TAKES} | {lid for _, lid, _ in LINES}:
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
.scene{font-size:.8rem;text-transform:uppercase;letter-spacing:.06em;color:var(--accent)}
textarea{width:100%;box-sizing:border-box;font:17px/1.4 system-ui;border:1px solid var(--line);border-radius:6px;padding:6px 8px;resize:vertical}
</style></head><body><main>
<h1>MWM Les: lydopptak</h1>
<p>Ti lyder: kort, og lang der lyden kan holdes (t og b er bare korte): kort (cirka et halvt sekund) og lang (hold lyden jevnt i cirka to sekunder).
Si bare lyden, aldri bokstavnavnet. Trykk Ta opp, si lyden, trykk Stopp. Hør på opptaket, og ta det på nytt hvis det ikke er riktig.</p>
<p>Stille rom, 20 til 30 cm fra mikrofonen.</p>
<section><h2>Korte lyder</h2></section><div id="short" style="display:grid;gap:10px"></div>
<section><h2>Lange lyder (hold i cirka 2 sekunder)</h2></section><div id="held" style="display:grid;gap:10px"></div>
<section><h2>Bokstavnavn (a, ess, i, ell, o, em)</h2></section><div id="names" style="display:grid;gap:10px"></div>
<section><h2>Pips replikker</h2><p>Les med vanlig, varm stemme, som til et barn på fem. Endre teksten fritt hvis den ikke er naturlig norsk; endringen lagres når du klikker utenfor feltet.</p></section><div id="lines" style="display:grid;gap:10px"></div>
</main><script>
const TAKES=__TAKES__;let rec=null,chunks=[],active=null;
function row(t){
 const d=document.createElement("div");d.className="take"+(t.saved?" saved":"");
 d.innerHTML=t.line!==undefined?`<span class="big">P</span><span class="info"><span class="scene">${t.scene}</span><textarea rows="2"></textarea></span>`
  :`<span class="big">${t.letter}</span><span class="info"><b>${t.word}${t.name?"":t.held?" (lang)":" (kort)"}</b>${t.tip}</span>`;
 d.innerHTML+=`
 <span class="btns"><button class="rec">Ta opp</button><button class="play">Hør</button></span><span class="state">${t.saved?"Lagret":"Ikke tatt opp ennå"}</span>`;
 const b=d.querySelector(".rec"),p=d.querySelector(".play"),s=d.querySelector(".state");
 const ta=d.querySelector("textarea");if(ta){ta.value=t.line;ta.onchange=()=>fetch("/text/"+t.id,{method:"POST",body:ta.value}).then(r=>s.textContent=r.ok?"Tekst lagret":"Kunne ikke lagre teksten")}
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
for(const t of TAKES)document.getElementById(t.line!==undefined?"lines":t.name?"names":t.held?"held":"short").append(row(t));
</script></body></html>"""

if __name__ == "__main__":
    print(f"Open http://localhost:{PORT} in your browser. Takes go to {OUT}")
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
