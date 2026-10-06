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
Pip wants to build a bridge of letters, one word at a time. One play is six word levels,
in this order: **sol, sel, les, mat, båt, lam**. Each level goes round the three
stations with its word: find its letters (Hør og finn), write them in the sand where they
become stones (Sandskriving), lay the stones as the word in the bridge (Ordbroa). The
bridge grows one word per level toward the islet; after `lam` the lamb walks over.

Letters come in with the level that first uses them: sol brings s, o, l; sel brings e;
les none; mat brings m, a, t; båt brings b, å; lam none. Progress (level and learned
letters) is saved after each level. A relaunch in the middle of a play greets with
`level_back` and goes on at that level. After lam the play is complete; a tap after
goodnight starts a new play from sol as a review (every letter known: no intro, no
model, no trace, one ask and one write per letter).

## Letter clips (a, s, i, l, o, m, e, t, b, å)

Letter order: a s i l o m e t b å (`LetterRules.ORDER`, one new letter at a time). File
ids spell å as `aa` (`lyd_aa`, `intro_aa`); the screen shows å.

| id | What it is |
|---|---|
| `lyd_x` | short sound (a tap on a letter, a touched stone) |
| `lyd_x_held` | held sound (the sound to find, Pip's pen drawing the letter). t and b have none: their `lyd_x` plays wherever a held sound would |
| `navn_x` | letter name: a, ess, i, ell, o, em, e, te, be, å (long-press) |
| `intro_x` | "Denne bokstaven heter <navn>. Den sier <lyd>." (a new letter, its tile glows) |
| `intro_again` | "Hør en gang til." right after `intro_x`, then the held sound once more |

## Opening (first launch only)

| id | Text | On screen |
|---|---|---|
| `op_1` | Hei! Jeg heter Pip. | Pip pops up out of the water |
| `op_2` | Ser du lammet på den lille øya der borte? Det er bestevennen min. | camera on the lamb on the islet |
| `op_3` | Han kan ikke svømme. Derfor vil jeg lage en bro. | the gap in the water |
| `op_4` | Broa skal vi lage av bokstaver. | l, a, m float up over the gap |
| `op_5` | Kan du hjelpe meg? Trykk på meg! | back by Pip, ghost finger taps Pip (repeats after 7 s) |
| `levels_intro` | Vi skal bygge seks ord. Hvert ord gjør broa lengre. | first play only, before the first level |

## Hub

| id | Text | When |
|---|---|---|
| `hub_back` | Hei igjen! Lammet venter på oss. | later launches and new days, before the first hub line |
| `hub_find` | Først må vi finne bokstavene. Bli med! | Hør og finn is lit |
| `hub_write` | Nå skal vi skrive bokstavene i sanden. | Sandskriving is lit |
| `hub_bridge` | Nå kan vi bygge broa. Kom! | Ordbroa is lit |
| `hub_idle` | Trykk der det lyser. | 7 s without a tap (ghost finger on the lit station) |

At the start of each level, before `hub_find`: `lamb_baa` ("Bææ!", the lamb hops on its
islet), then the word's `hook_<w>` while its picture pops up beside Pip (lam: no picture,
the lamb is on its islet). A relaunch mid-play starts with `level_back` ("Hei igjen! Vi
fortsetter der vi slapp.").

## Hør og finn

| id | Text | When |
|---|---|---|
| `find_in` | Her i sanden ligger det bokstaver. Hør godt etter! | station start |
| `find_ask` | Hvilken bokstav sier dette? | every item, then the target's `lyd_x_held` (nothing after it) |
| `find_right` | Ja! Den fant du. | after every right answer (after a chime) |
| `find_wrong` | Den sier noe annet. Hør en gang til. | after tapped `lyd_y` and `sfx_tok`, then the target's `lyd_x_held` |
| `find_done` | Nå har vi funnet nok bokstaver. Bra jobba! | after the last item |

Tiles: the word's letters plus at most one letter learned before. Each letter of the word
is asked 2 times (owner: 2-3 slow repetitions), shuffled, never the same letter twice in a
row; 6 items for a 3-letter word (review: once each). The word's new letters at the first
item: `intro_x` while its tile glows, then `intro_again` and its held sound (t, b: short
sound).

## Sandskriving

| id | Text | When |
|---|---|---|
| `write_in` | Nå skal du skrive i sanden. Se på meg først. | first letter |
| `write_next` | Nå skriver vi en bokstav til. | each letter after the first |
| `write_show_again` | Se på meg en gang til. | a new letter: before Pip's second model |
| `write_trace` | Nå følger du stripene med fingeren. | a new letter: the letter lies striped in the sand |
| `write_alone` | Nå skriver du helt selv. | before the free write (a learned letter: then its held sound) |
| `write_retry` | Nesten! Prøv en gang til. | a letter or trace that is not accepted |
| `write_right` | Så fint! Den blir en stein til broa. | every accepted letter; the stone lifts out and rolls to the bridge |
| `write_done` | Nå har vi nok steiner. Vi tar dem med til broa. | last stone |

The child writes each letter of the level's word once; every stone is laid in that word.
A letter that is new in this level: Pip's pen draws the model while its held sound plays,
then `write_show_again` and the model once more; then `write_trace`: the letter lies as a
striped path (gold and dark stripes, an arrow and a start dot) and the child follows it
(counts at 90 % coverage, after 3 tries anyway; a chime); then `write_alone` and the
child writes it on empty sand (lenient check). A letter learned in an earlier level (and
every letter in a review): `write_alone` + its held sound, one write.

## Ordbroa (one word per level)

| word | `hook_<id>` (hub) | picture | `mid_<id>` (bridge) | `done_<id>` |
|---|---|---|---|---|
| sol | Se, sola skinner! | the sun in the sky | Sola varmer. Da er det lett å bygge! | Sola skinner på broa. Nå blir det varmt og godt! |
| sel | Se! En sel svømmer i vannet. | a seal in the water | Selen dykker under broa! | Selen klapper med luffene. Den vil se broa bli ferdig. |
| les | Jeg har en bok. Jeg liker å lese. | an open book by Pip | Jeg tar med boka. Vi kan lese for lammet når broa er ferdig. | Jeg leser ordene på broa for lammet. Det liker lammet! |
| mat | Lammet er sultent. Det trenger mat. | a bowl of hay by the lamb | Lammet er så sultent. Vi må gi det mat! | Nå har lammet fått mat. Nam nam! |
| båt (`baat`) | Se der! En båt på sjøen. | a sailing boat in the bay | Båten kommer nærmere. Se, den har seil! | Båten tuter: tuut! Den seiler forbi broa vår. |
| lam | Og så det viktigste ordet. Det er lammet sitt ord! | the lamb hops | none | `bridge_done` |

| id | Text | When |
|---|---|---|
| `bridge_in` | Nå bygger vi broa. Hver stein er en bokstav. | level 1 only |
| `mid_<id>` | (table) | while the word's picture shows |
| `bridge_word_<id>` | Vi skal skrive sol. Hør: sss, ooo, lll. Sol! (per word) | the planks light at the measured sound onsets, all at the word |
| `bridge_ask` | Hvilken bokstav mangler? | each plank, then its `lyd_x_held` (t, b: `lyd_x`) |
| `bridge_right` | Ja! Der passet den. | every right stone (after a chime) |
| `done_<id>` | (table) | the word is laid; its letters and planks sink into the deck |
| `level_next` | Hurra! Nå går vi videre til neste ord. | end of every level but lam |
| `bridge_done` | Broa er ferdig! Der står det lam. | lam laid: the deck reaches the islet |
| `bridge_walk` | Se, lammet kommer over broa! Takk for hjelpen! | while the lamb crosses |
| `final_party` | Lammet er her! Nå kan vi leke sammen hver dag. | the lamb is over: bursts, Pip giggles; then goodnight |

A wrong stone: its `lyd_y`, `sfx_tok`, then the plank's held sound again.

The bridge (about 8 m) cannot hold 18 full planks, so it grows like this: the current
word gets full-size planks (1.2 m pitch) right after the deck of the earlier levels; when
the word is done its planks sink and a plain deck section (about 0.75 m) rises in their
place. At lam the planks end at the islet and the deck reaches it.

## End

| id | Text | When |
|---|---|---|
| `end_bye` | Nå er jeg trøtt. Takk for i dag, ha det! | after the bridge, sunset; a tap starts a new day |
