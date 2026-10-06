# MWM Les

A 3D reading adventure for Norwegian children aged 4 to 7. The child sails to a grey
island with Pip, a small narwhal, learns the sounds of the letters, and brings colour
and life back to the island one sound at a time. Every instruction is spoken in
Norwegian (bokmål), so a child who cannot read yet can play alone.
**No ads, no in-app purchases, no timers, no tracking, no internet permission.**

The teaching is built on reading research, with the sources checked one by one in
[docs/RESEARCH.md](docs/RESEARCH.md): letter sounds in a fixed order, sounds held and
blended together (/sssooolll/ → *sol*), letters written from memory instead of traced,
and a grown-up who listens to the child read at the end of every session.

<p align="center">
  <img src="screenshots/01.jpg" alt="The island restored to full colour, with Pip the narwhal in the sea" width="400"/>
  <img src="screenshots/02.jpg" alt="Pip says a sound and the child taps the matching gold letter" width="400"/>
</p>
<p align="center">
  <img src="screenshots/03.jpg" alt="Letter stones to build a word bridge" width="400"/>
  <img src="screenshots/04.jpg" alt="The grey island at the start of a session" width="400"/>
</p>

## Download

**Direct APK download:**
https://github.com/Matswm86/mwm-les/releases/download/latest/mwm-les.apk

1. Open that link in your phone's or tablet's browser and tap to download.
2. When you open the file, Android may ask you to allow installs from this source.
   Tap **Settings**, turn on **Allow from this source**, go back and install.
3. The app appears as **MWM Les**. It plays in landscape.

The APK is debug-signed with a stable key, so a newer build installs over an older one
and keeps the child's progress. Builds made before 3 October 2026 at 21:30 used a
one-off key: uninstall that version once before installing a newer one.

## How to play

Pip the narwhal's best friend, a lamb, stands on a little islet across the water and
cannot swim. Pip wants to build a bridge of letters, and the child helps. On the first
launch Pip tells this in a short opening; the child taps Pip to start. Pip then swims
to one lit station at a time.

| Activity | What the child does | Based on |
|---|---|---|
| Hør og finn (listen and find) | Pip asks which letter says a sound, then plays the sound. The child taps the letter on the sand tiles; a tapped letter says its own sound. A new letter is introduced by name and sound while its tile glows. Press and hold a letter to hear its name and sound. | Systematic letter-sound teaching |
| Sandskriving (sand writing) | Pip writes the letter in the sand while its sound plays, then the child writes it with a finger. An accepted letter lifts out as a stone and rolls off to the bridge. | Handwriting from memory, not tracing |
| Ordbroa (the word bridge) | Pip says `lam` and sounds it out while the planks light up, then asks which letter is missing. The child drags the right stone into the gap. When the bridge is done the letters sink into the planks and the lamb walks over. | Moveable alphabet, connected blending |

Then Pip says goodnight. A tap starts a new day. Wrong answers never end anything: the
letter says its own sound and the child hears the right sound again.

## Status

Early test build: the first island with the first six sounds (a, s, i, l, o, m).
The design for the full game, six worlds from listening games to reading a whole
story, is in [docs/GDD.md](docs/GDD.md).

## How it works

- `scripts/learn_core/` is a learning engine with no reading knowledge in it. It keeps
  a mastery estimate per skill, picks tasks the child gets right about 70-85% of the
  time, and runs the hint ladder. A content pack drives it; the reading pack is
  `content/nb_reading/` (`skills.json` holds the sound order, `items.json` the tasks),
  so a maths pack can reuse the same engine.
- The cel-shaded look comes from a toon light shader (`shaders/toon.gdshader`) with a
  two-tone shadow, an outline shell on things the child can touch, and unshaded gold
  letters with a halo.
- Every spoken line is a real person's recording (`assets/audio/rec/`, one file per
  line id in `docs/SCRIPT.md`), so the app never needs the internet and uses no
  synthetic voice. The `Voice` autoload is the only sound source: one player, so two
  clips never overlap, and it refuses any file that is not one of these recordings or
  a short sound effect. A letter sound always comes last in a sequence.

## Credits

- Hero: [KayKit Adventurers](https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0)
  by Kay Lousberg (CC0). Full asset list and licences: [docs/ASSETS.md](docs/ASSETS.md).
- Font: [Andika](https://software.sil.org/andika/) by SIL, designed for beginning
  readers (SIL Open Font License, see `assets/fonts/OFL.txt`).

## Run from source

1. Install **Godot 4.6.x** from https://godotengine.org/.
2. Import `project.godot` and press **F5**. The mouse works as a finger.

The engine tests run headless from `tests/`. `tests/capture.tscn` is a dev-only scene
(not exported) where a bot plays the whole island and saves screenshots; run it under
Xvfb with `CAPTURE_DIR=/some/dir` and `--audio-driver Dummy`.

## Build

GitHub Actions builds the APK on every push to `main`
(`.github/workflows/build-android.yml`) and publishes it to the rolling `latest`
release.

## License

Code: MIT (see `LICENSE`). Third-party assets keep their own licences, listed in
[docs/ASSETS.md](docs/ASSETS.md).
