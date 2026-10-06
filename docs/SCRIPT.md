# MWM Les: voice script (island 1, "the bridge to the lamb")

Every spoken line is one recording in `assets/audio/rec/<id>.wav` (mono, 48 kHz),
recorded by a real person. No synthetic voice is used anywhere. The text below is what
was recorded (checked with Whisper). The `Voice` autoload refuses any id that is not
listed here or a non-voice effect (`sfx_*`).

Rules (enforced in `scripts/Voice.gd`, checked by `tests/full_flow_check.gd`):

- One player: two clips never overlap; a new sequence stops the old one.
- Sentence first, sound last: inside one sequence no sentence follows a letter sound.
- A letter only ever plays its own files.

## Story

Pip's best friend, the lamb, is on the little islet across the water and cannot swim.
Pip wants to build a bridge of letters. The child finds letters (Hør og finn), writes
them in the sand where they become stones (Sandskriving), and lays the stones as the
bridge spelling `lam` (Ordbroa). When the bridge is done the lamb walks over.

## Letter clips (a, s, i, l, o, m)

| id | What it is |
|---|---|
| `lyd_x` | short sound (a tap on a letter, a touched stone) |
| `lyd_x_held` | held sound (the sound to find, Pip's pen drawing the letter) |
| `navn_x` | letter name: a, ess, i, ell, o, em (long-press) |
| `intro_x` | "Denne bokstaven heter <navn>. Den sier <lyd>." (a new letter, its tile glows) |

## Opening (first launch only)

| id | Text | On screen |
|---|---|---|
| `op_1` | Hei! Jeg heter Pip. | Pip pops up out of the water |
| `op_2` | Ser du lammet på den lille øya der borte? Det er bestevennen min. | camera on the lamb on the islet |
| `op_3` | Han kan ikke svømme. Derfor vil jeg lage en bro. | the gap in the water |
| `op_4` | Broa skal vi lage av bokstaver. | l, a, m float up over the gap |
| `op_5` | Kan du hjelpe meg? Trykk på meg! | back by Pip, ghost finger taps Pip (repeats after 7 s) |

## Hub

| id | Text | When |
|---|---|---|
| `hub_back` | Hei igjen! Lammet venter på oss. | later launches and new days, before the first hub line |
| `hub_find` | Først må vi finne bokstavene. Bli med! | Hør og finn is lit |
| `hub_write` | Nå skal vi skrive bokstavene i sanden. | Sandskriving is lit |
| `hub_bridge` | Nå kan vi bygge broa. Kom! | Ordbroa is lit |
| `hub_idle` | Trykk der det lyser. | 7 s without a tap (ghost finger on the lit station) |

## Hør og finn

| id | Text | When |
|---|---|---|
| `find_in` | Her i sanden ligger det bokstaver. Hør godt etter! | station start |
| `find_ask` | Hvilken bokstav sier dette? | every item, then the target's `lyd_x_held` (nothing after it) |
| `find_right` | Ja! Den fant du. | every third right answer (otherwise a chime only) |
| `find_wrong` | Den sier noe annet. Hør en gang til. | after tapped `lyd_y` and `sfx_tok`, then the target's `lyd_x_held` |
| `find_done` | Nå har vi funnet nok bokstaver. Bra jobba! | after 6 items |

## Sandskriving

| id | Text | When |
|---|---|---|
| `write_in` | Nå skal du skrive i sanden. Se på meg først. | first letter |
| `write_turn` | Nå er det din tur. Skriv med fingeren. | after Pip's model (drawn while `lyd_x_held` plays) |
| `write_retry` | Nesten! Prøv en gang til. | a letter that is not accepted |
| `write_right` | Så fint! Den blir en stein til broa. | accepted; the stone lifts out and rolls to the bridge |
| `write_done` | Nå har vi nok steiner. Vi tar dem med til broa. | last stone |

## Ordbroa (word `lam`)

| id | Text | When |
|---|---|---|
| `bridge_in` | Nå bygger vi broa. Hver stein er en bokstav. | station start |
| `bridge_word_lam` | Vi skal skrive lam. Hør: l… a… m. Lam! | planks l, a, m light at 3.68, 5.20 and 6.82 s, all at 8.40 s (`content/nb_reading/clip_marks.json`) |
| `bridge_ask` | Hvilken bokstav mangler? | each missing plank, then its `lyd_x_held` |
| `bridge_right` | Ja! Der passet den. | the right stone (after a chime) |
| `bridge_done` | Broa er ferdig! Der står det lam. | all planks lit, then the letters sink into the planks |
| `bridge_walk` | Se, lammet kommer over broa! Takk for hjelpen! | while the lamb crosses |

A wrong stone: its `lyd_y`, `sfx_tok`, then the plank's `lyd_x_held` again.

Which planks are missing: the letters of `lam` the child has met in Hør og finn (at
first only `a`; `l` and `m` lie ready as planks). Sandskriving writes exactly those
letters plus one spare known letter (while fewer than three are missing), so the
stones on the raft are the child's own.

## End

| id | Text | When |
|---|---|---|
| `end_bye` | Nå er jeg trøtt. Takk for i dag, ha det! | after the bridge, sunset; a tap starts a new day |
