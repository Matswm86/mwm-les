"""Clean the owner's raw takes for the game.

recorded/<id>.wav -> recorded/clean/<id>.wav and assets/audio/rec/<id>.wav:
highpass 80 Hz, light denoise (game copies spell å as aa), trim to where the 20 ms RMS first and last
reaches 12% of its peak (plus 60 ms room), mono 48 kHz, -18 LUFS.
Run: ~/MWM/data/tools/clone-venv/bin/python tools/clean_takes.py [id ...]
(no ids = every raw take that has no clean copy yet).
"""

import subprocess
import sys
from pathlib import Path

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "recorded"
CLEAN = RAW / "clean"
GAME = ROOT / "assets" / "audio" / "rec"
FRAME_SEC = 0.02
PEAK_SHARE = 0.12
PAD_SEC = 0.06


def ffmpeg(src: Path, dst: Path, af: str) -> None:
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", str(src), "-af", af, "-ac", "1", "-ar", "48000", str(dst)],
        check=True,
    )


def clean(tid: str) -> float:
    src = RAW / f"{tid}.wav"
    tmp = CLEAN / f"{tid}.tmp.wav"
    ffmpeg(src, tmp, "highpass=f=80,afftdn=nf=-25")
    x, sr = sf.read(tmp)
    n = int(sr * FRAME_SEC)
    rms = np.array([np.sqrt(np.mean(x[i : i + n] ** 2)) for i in range(0, len(x) - n, n)])
    loud = np.nonzero(rms >= rms.max() * PEAK_SHARE)[0]
    pad = int(sr * PAD_SEC)
    a = max(0, loud[0] * n - pad)
    b = min(len(x), (loud[-1] + 1) * n + pad)
    sf.write(tmp, x[a:b], sr)
    out = CLEAN / f"{tid}.wav"
    ffmpeg(tmp, out, "loudnorm=I=-18:TP=-1:LRA=7")
    tmp.unlink()
    GAME.mkdir(parents=True, exist_ok=True)
    (GAME / out.name.replace("å", "aa")).write_bytes(out.read_bytes())  # ASCII names for Android
    return (b - a) / sr


def main() -> None:
    CLEAN.mkdir(exist_ok=True)
    ids = sys.argv[1:] or [p.stem for p in sorted(RAW.glob("*.wav")) if not (CLEAN / p.name).exists()]
    for tid in ids:
        print(f"{tid}: {clean(tid):.2f} s")


if __name__ == "__main__":
    main()
