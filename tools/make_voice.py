#!/usr/bin/env python3
"""Regenerate every voice clip from tools/voice_lines.tsv.

PLACEHOLDER VOICE. The final voice is not chosen (the owner rejected every free
TTS voice tried so far). These clips exist only so the game's wiring can be
tested; every manifest entry is "placeholder" and QA blocks a release on that.
A real recording replaces assets/audio/tts_<id>.mp3 under the same file name.

Dev-time only: the app never calls a TTS service. Output goes to
assets/audio/tts_<id>.mp3 (one file per line, mono, 48 kHz, -18 LUFS
integrated, peaks at most -1 dBTP), content/nb_reading/audio_manifest.json and
content/nb_reading/clip_marks.json (sound start times inside [lydering:x]).

Modes in the lines file:
  say      the whole text, edge-tts, voice VOICE at rate RATE
  hysj     the whole text in Kaptein Hysj's voice HYSJ_VOICE at rate RATE
  phoneme  a carrier sentence at PHONEME_RATE; the last word is located with
           faster-whisper word timestamps and cut out, silence trimmed and
           stretched 2x (atempo=0.5). A bare "sss" makes the voice spell the
           letter, so the carrier is needed.
  hold     `text` names a phoneme clip; it is stretched to HOLD_SEC
  concat   `text` names clips joined with CONCAT_GAP_SEC of silence; the start
           of each clip is written to clip_marks.json

Usage (swap the voice by setting MWM_LES_VOICE / MWM_LES_HYSJ_VOICE):
  python3 tools/make_voice.py            # make missing clips
  python3 tools/make_voice.py --force    # remake all
  python3 tools/make_voice.py --only lyd_s ord_lam
Env: EDGE_TTS (edge-tts binary, default "edge-tts"), FFMPEG (default "ffmpeg"),
FFPROBE (default "ffprobe"). Phoneme mode needs faster-whisper importable by the
Python running this script.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LINES = ROOT / "tools" / "voice_lines.tsv"
OUT_DIR = ROOT / "assets" / "audio"
MANIFEST = ROOT / "content" / "nb_reading" / "audio_manifest.json"
MARKS = ROOT / "content" / "nb_reading" / "clip_marks.json"
VOICE = os.environ.get("MWM_LES_VOICE", "nb-NO-FinnNeural")
# Kaptein Hysj speaks with a different voice than Pip (GDD 13).
HYSJ_VOICE = os.environ.get("MWM_LES_HYSJ_VOICE", "nb-NO-PernilleNeural")
RATE = "-15%"
PHONEME_RATE = "-30%"
HOLD_SEC = 1.5
CONCAT_GAP_SEC = 0.25
EDGE_TTS = os.environ.get("EDGE_TTS", "edge-tts")
FFMPEG = os.environ.get("FFMPEG", "ffmpeg")
FFPROBE = os.environ.get("FFPROBE", "ffprobe")
LOUDNESS = "I=-18:TP=-1:LRA=11"
# The TTS lead-in and the ~1 s tail of silence are trimmed to a short pad.
TRIM_FILTER = (
    "silenceremove=start_periods=1:start_threshold=-45dB,areverse,"
    "silenceremove=start_periods=1:start_threshold=-45dB,areverse,"
    "adelay=60,apad=pad_dur=0.15"
)
CUT_FILTER = (
    "silenceremove=start_periods=1:start_threshold=-40dB,areverse,"
    "silenceremove=start_periods=1:start_threshold=-40dB,areverse,"
    "atempo=0.5,afade=t=in:d=0.05"
)
PLACEHOLDER_NOTE = "placeholder voice, final voice not chosen; replace the file under the same name"


def read_lines() -> list[tuple[str, str, str]]:
    rows = []
    for raw in LINES.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.startswith("#"):
            continue
        clip_id, mode, text = raw.split("\t", 2)
        rows.append((clip_id.strip(), mode.strip(), text.strip()))
    return rows


def ff(*args: str) -> None:
    subprocess.run([FFMPEG, "-v", "error", "-y", *args], check=True)


def duration(path: Path) -> float:
    out = subprocess.run(
        [FFPROBE, "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        check=True,
        capture_output=True,
        text=True,
    )
    return float(out.stdout.strip())


def normalize(src: Path, out: Path) -> None:
    """Two-pass EBU R128 loudness to -18 LUFS, mono, 48 kHz."""
    probe = subprocess.run(
        [
            FFMPEG,
            "-hide_banner",
            "-i",
            str(src),
            "-af",
            f"loudnorm={LOUDNESS}:print_format=json",
            "-f",
            "null",
            "-",
        ],
        check=True,
        capture_output=True,
        text=True,
    ).stderr
    m = json.loads(probe[probe.rindex("{") : probe.rindex("}") + 1])
    second = (
        f"loudnorm={LOUDNESS}:measured_I={m['input_i']}:measured_TP={m['input_tp']}"
        f":measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}"
        f":offset={m['target_offset']}:linear=true"
    )
    ff("-i", str(src), "-af", second, "-ac", "1", "-ar", "48000", str(out))


def tts(text: str, rate: str, out: Path, voice: str = VOICE) -> None:
    subprocess.run(
        [EDGE_TTS, "--voice", voice, f"--rate={rate}", "--text", text, "--write-media", str(out)],
        check=True,
    )


def make_spoken(text: str, out: Path, voice: str, tmp: Path) -> None:
    raw = tmp / "raw.mp3"
    trimmed = tmp / "trimmed.wav"
    tts(text, RATE, raw, voice)
    ff("-i", str(raw), "-af", TRIM_FILTER, str(trimmed))
    normalize(trimmed, out)


def make_phoneme(text: str, out: Path, model: object, tmp: Path) -> None:
    carrier = tmp / "carrier.mp3"
    cut = tmp / "cut.wav"
    tts(text, PHONEME_RATE, carrier)
    segs, _ = model.transcribe(str(carrier), language="no", word_timestamps=True)
    words = [w for s in segs for w in s.words]
    if not words:
        raise RuntimeError(f"no words found in {text!r}")
    last = words[-1]
    ff(
        "-i",
        str(carrier),
        "-ss",
        f"{max(last.start - 0.05, 0.0):.3f}",
        "-to",
        f"{last.end + 0.15:.3f}",
        "-af",
        CUT_FILTER,
        str(cut),
    )
    normalize(cut, out)


def make_hold(src_id: str, out: Path, tmp: Path) -> None:
    src = OUT_DIR / f"tts_{src_id}.mp3"
    factor = duration(src) / HOLD_SEC
    stages = []
    while factor < 0.5:
        stages.append("atempo=0.5")
        factor /= 0.5
    stages.append(f"atempo={factor:.4f}")
    held = tmp / "held.wav"
    ff(
        "-i",
        str(src),
        "-af",
        ",".join(stages) + ",afade=t=out:st=" + f"{HOLD_SEC - 0.12:.2f}:d=0.12",
        str(held),
    )
    normalize(held, out)


def make_concat(src_ids: list[str], out: Path, tmp: Path) -> list[float]:
    marks = []
    t = 0.0
    inputs: list[str] = []
    for k, sid in enumerate(src_ids):
        src = OUT_DIR / f"tts_{sid}.mp3"
        if k > 0:
            t += CONCAT_GAP_SEC
        marks.append(round(t, 3))
        t += duration(src)
        inputs += ["-i", str(src)]
    n = len(src_ids)
    pad = f"apad=pad_dur={CONCAT_GAP_SEC}"
    chain = ";".join(
        f"[{k}:a]aresample=48000,{pad}[p{k}]" if k < n - 1 else f"[{k}:a]aresample=48000[p{k}]"
        for k in range(n)
    )
    joined = tmp / "joined.wav"
    ff(
        *inputs,
        "-filter_complex",
        chain + ";" + "".join(f"[p{k}]" for k in range(n)) + f"concat=n={n}:v=0:a=1[o]",
        "-map",
        "[o]",
        str(joined),
    )
    normalize(joined, out)
    return marks


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--only", nargs="*", default=None)
    args = ap.parse_args()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = read_lines()
    marks: dict[str, list[float]] = (
        json.loads(MARKS.read_text(encoding="utf-8")).get("marks", {}) if MARKS.exists() else {}
    )
    model = None
    manifest = []
    for clip_id, mode, text in rows:
        out = OUT_DIR / f"tts_{clip_id}.mp3"
        wanted = args.only is None or clip_id in args.only
        if wanted and (args.force or not out.exists()):
            print(f"make {out.name}: {text}")
            with tempfile.TemporaryDirectory() as tmp_name:
                tmp = Path(tmp_name)
                if mode == "say":
                    make_spoken(text, out, VOICE, tmp)
                elif mode == "hysj":
                    make_spoken(text, out, HYSJ_VOICE, tmp)
                elif mode == "phoneme":
                    if model is None:
                        from faster_whisper import WhisperModel  # noqa: PLC0415

                        model = WhisperModel("small", device="cpu", compute_type="int8")
                    make_phoneme(text, out, model, tmp)
                elif mode == "hold":
                    make_hold(text, out, tmp)
                elif mode == "concat":
                    marks[clip_id] = make_concat(text.split(), out, tmp)
                else:
                    print(f"unknown mode {mode} for {clip_id}", file=sys.stderr)
                    return 1
        voice = HYSJ_VOICE if mode == "hysj" else VOICE
        manifest.append(
            {
                "id": clip_id,
                "file": f"res://assets/audio/{out.name}",
                "mode": mode,
                "text": text,
                "voice": f"{voice} (edge-tts)",
                "status": "placeholder",
                "note": PLACEHOLDER_NOTE,
            }
        )
    MANIFEST.write_text(
        json.dumps({"pack": "nb_reading", "clips": manifest}, ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )
    MARKS.write_text(
        json.dumps(
            {
                "note": "Start time in seconds of each sound inside a [lydering:x] clip, in order. "
                "The bridge lights plank i at marks[i]. Re-measure when a real recording replaces the clip.",
                "marks": {k: marks[k] for k in sorted(marks)},
            },
            ensure_ascii=False,
            indent=1,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"{len(manifest)} clips listed in {MANIFEST.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
