#!/usr/bin/env bash
# Synthesises the small sound effects (no samples, no licences): a pentatonic
# chime ladder for right answers, a soft wooden "tok", a tap "pop" and a
# whoosh. Usage: tools/make_sfx.sh   (needs ffmpeg on PATH or $FFMPEG)
set -euo pipefail
cd "$(dirname "$0")/.."
FF="${FFMPEG:-ffmpeg}"
out=assets/audio
i=0
for f in 523.25 587.33 659.25 783.99 880.00 1046.50; do
	"$FF" -v quiet -y -f lavfi -i "aevalsrc='0.35*sin(2*PI*$f*t)*exp(-4*t)+0.12*sin(4*PI*$f*t)*exp(-7*t)':d=0.9:s=44100" \
		-af "afade=t=in:d=0.005" "$out/sfx_chime_$i.wav"
	i=$((i + 1))
done
"$FF" -v quiet -y -f lavfi -i "aevalsrc='0.5*sin(2*PI*(260-120*t)*t)*exp(-30*t)':d=0.25:s=44100" "$out/sfx_tok.wav"
"$FF" -v quiet -y -f lavfi -i "aevalsrc='0.4*sin(2*PI*(500+1400*t)*t)*exp(-25*t)':d=0.18:s=44100" "$out/sfx_pop.wav"
"$FF" -v quiet -y -f lavfi -i "anoisesrc=d=0.7:c=pink:a=0.25" -af "bandpass=f=900:w=600,afade=t=in:d=0.3,afade=t=out:st=0.35:d=0.35" "$out/sfx_whoosh.wav"
"$FF" -v quiet -y -f lavfi -i "aevalsrc='0.3*(sin(2*PI*523.25*t)+sin(2*PI*659.25*t)*gte(t,0.15)+sin(2*PI*783.99*t)*gte(t,0.3)+sin(2*PI*1046.5*t)*gte(t,0.45))*exp(-1.6*t)':d=1.4:s=44100" "$out/sfx_fanfare.wav"
ls "$out"/sfx_* | wc -l
