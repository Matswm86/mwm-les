#!/usr/bin/env python3
"""Regenerate every placeholder voice clip from tools/voice_lines.tsv.

Dev-time only: the app never calls a TTS service. Output goes to
assets/audio/tts_<id>.mp3 (tts_ = machine voice) and
content/nb_reading/audio_manifest.json. Microsoft Finn is the chosen final
voice (owner decision 2026-10-03), so clips are "final"; cut sounds the owner
still has to judge by ear are "review". QA blocks a release on "placeholder"
or "review".

Modes in the lines file:
  say      the whole text, edge-tts, voice VOICE at rate RATE
  hysj     the whole text in Kaptein Hysj's voice HYSJ_VOICE at rate RATE
  phoneme  a carrier sentence at PHONEME_RATE; the last word is located with
           faster-whisper word timestamps and cut out, silence trimmed,
           stretched 2x (atempo=0.5) and loudness-normalised. A bare "sss"
           makes the voice spell the letter, so the carrier is needed.

Usage (swap the voice by editing VOICE or setting MWM_LES_VOICE):
  python3 tools/make_voice.py            # make missing clips
  python3 tools/make_voice.py --force    # remake all
  python3 tools/make_voice.py --only ph_s w_sol
Env: EDGE_TTS (edge-tts binary, default "edge-tts"), FFMPEG (default "ffmpeg").
Phoneme mode needs faster-whisper importable by the Python running this script.
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
VOICE = os.environ.get("MWM_LES_VOICE", "nb-NO-FinnNeural")
# Kaptein Hysj speaks with a different voice than Pip (GDD 13).
HYSJ_VOICE = os.environ.get("MWM_LES_HYSJ_VOICE", "nb-NO-PernilleNeural")
RATE = "-15%"
PHONEME_RATE = "-30%"
EDGE_TTS = os.environ.get("EDGE_TTS", "edge-tts")
FFMPEG = os.environ.get("FFMPEG", "ffmpeg")
# Cut sounds the owner still has to approve by ear (status "review").
REVIEW = {
    "ph_i": "cut letter sound may be unclear; owner to check by ear",
    "ph_o": "cut letter sound may be unclear; owner to check by ear",
}
# Spoken lines are chained into prompts ("Hvor er" + sss + "Trykk på" + sss),
# so the TTS lead-in and the ~1 s tail of silence are trimmed to a short pad.
TRIM_FILTER = (
    "silenceremove=start_periods=1:start_threshold=-45dB,areverse,"
    "silenceremove=start_periods=1:start_threshold=-45dB,areverse,"
    "adelay=60,apad=pad_dur=0.15"
)
CUT_FILTER = (
    "silenceremove=start_periods=1:start_threshold=-40dB,areverse,"
    "silenceremove=start_periods=1:start_threshold=-40dB,areverse,"
    "atempo=0.5,afade=t=in:d=0.05,loudnorm"
)


def read_lines() -> list[tuple[str, str, str]]:
    rows = []
    for raw in LINES.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.startswith("#"):
            continue
        clip_id, mode, text = raw.split("\t", 2)
        rows.append((clip_id.strip(), mode.strip(), text.strip()))
    return rows


def tts(text: str, rate: str, out: Path, voice: str = VOICE) -> None:
    subprocess.run(
        [EDGE_TTS, "--voice", voice, f"--rate={rate}", "--text", text, "--write-media", str(out)],
        check=True,
    )


def tts_trimmed(text: str, rate: str, out: Path, voice: str) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "raw.mp3"
        tts(text, rate, raw, voice)
        subprocess.run(
            [FFMPEG, "-v", "quiet", "-y", "-i", str(raw), "-af", TRIM_FILTER, str(out)],
            check=True,
        )


def cut_last_word(carrier: Path, out: Path, model: object) -> None:
    segs, _ = model.transcribe(str(carrier), language="no", word_timestamps=True)
    words = [w for s in segs for w in s.words]
    if not words:
        raise RuntimeError(f"no words found in {carrier}")
    last = words[-1]
    subprocess.run(
        [
            FFMPEG,
            "-v",
            "quiet",
            "-y",
            "-i",
            str(carrier),
            "-ss",
            f"{max(last.start - 0.05, 0.0):.3f}",
            "-to",
            f"{last.end + 0.15:.3f}",
            "-af",
            CUT_FILTER,
            "-ar",
            "44100",
            "-ac",
            "1",
            str(out),
        ],
        check=True,
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--only", nargs="*", default=None)
    args = ap.parse_args()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = read_lines()
    model = None
    manifest = []
    for clip_id, mode, text in rows:
        out = OUT_DIR / f"tts_{clip_id}.mp3"
        wanted = args.only is None or clip_id in args.only
        if wanted and (args.force or not out.exists()):
            print(f"make {out.name}: {text}")
            if mode == "say":
                tts_trimmed(text, RATE, out, VOICE)
            elif mode == "hysj":
                tts_trimmed(text, RATE, out, HYSJ_VOICE)
            elif mode == "phoneme":
                if model is None:
                    from faster_whisper import WhisperModel  # noqa: PLC0415

                    model = WhisperModel("small", device="cpu", compute_type="int8")
                with tempfile.TemporaryDirectory() as tmp:
                    carrier = Path(tmp) / "carrier.mp3"
                    tts(text, PHONEME_RATE, carrier)
                    cut_last_word(carrier, out, model)
            else:
                print(f"unknown mode {mode} for {clip_id}", file=sys.stderr)
                return 1
        entry = {
            "id": clip_id,
            "file": f"res://assets/audio/{out.name}",
            "mode": mode,
            "text": text,
            "voice": f"{HYSJ_VOICE if mode == 'hysj' else VOICE} (edge-tts)",
            "status": "final",
        }
        if clip_id in REVIEW:
            entry["status"] = "review"
            entry["note"] = REVIEW[clip_id]
        manifest.append(entry)
    MANIFEST.write_text(
        json.dumps({"pack": "nb_reading", "clips": manifest}, ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )
    print(f"{len(manifest)} clips listed in {MANIFEST.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
