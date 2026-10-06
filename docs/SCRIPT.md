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
them in the sand where they become stones (Sandskriving), and lays the stones as a bridge
of words: up to two story words, then `lam`, always last (Ordbroa). When the bridge is
done the lamb walks over.

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
| `find_right` | Ja! Den fant du. | after every right answer (after a chime) |
| `find_wrong` | Den sier noe annet. Hør en gang til. | after tapped `lyd_y` and `sfx_tok`, then the target's `lyd_x_held` |
| `find_done` | Nå har vi funnet nok bokstaver. Bra jobba! | after 10 items |

A new letter at the start of an item: `intro_x` while its tile glows, then `intro_again`
and its held sound (t, b: short sound).

## Sandskriving

| id | Text | When |
|---|---|---|
| `write_in` | Nå skal du skrive i sanden. Se på meg først. | first letter |
| `write_next` | Nå skriver vi en bokstav til. | a new letter after the first |
| `write_turn` | Nå er det din tur. Skriv med fingeren. | after Pip's model (drawn while `lyd_x_held` plays) |
| `write_again` | Skriv den en gang til. | the same letter again right after: then its held sound, and the child writes it from memory (no model) |
| `write_retry` | Nesten! Prøv en gang til. | a letter that is not accepted |
| `write_right` | Så fint! Den blir en stein til broa. | every accepted letter; the stone lifts out and rolls to the bridge |
| `write_done` | Nå har vi nok steiner. Vi tar dem med til broa. | last stone |

The child writes exactly the letters today's bridge is missing (`Main.plan()`,
`BridgeWords.plan`), at most 6 per session, so every stone is laid in the bridge. A
letter needed twice is written twice, the second time right after the first.

## Ordbroa (words)

Words (`scripts/BridgeWords.gd`), each with a story line said while its picture shows:

| word | `hook_<id>` | picture | `bridge_word_<id>` |
|---|---|---|---|
| sol | Se, sola skinner! | the sun in the sky | Vi skal skrive sol. Hør: sss, ooo, lll. Sol! |
| sel | Se! En sel svømmer i vannet. | a seal in the water | Vi skal skrive sel. Hør: sss, eee, lll. Sel! |
| båt (`baat`) | Se der! En båt på sjøen. | a sailing boat in the bay | Vi skal skrive båt. Hør: b, ååå, t. Båt! |
| mat | Lammet er sultent. Det trenger mat. | a bowl of hay by the lamb | Vi skal skrive mat. Hør: mmm, aaa, t. Mat! |
| les | Jeg har en bok. Jeg liker å lese. | an open book by Pip | Vi skal skrive les. Hør: lll, eee, sss. Les! |
| lam | Og så det viktigste ordet. Det er lammet sitt ord! | the lamb hops | Vi skal skrive lam. Hør: l… a… m. Lam! |

Which words: up to two story words, then `lam`, always last. A story word needs at least
one letter the child has met and both its clips plus its letter marks
(`content/nb_reading/clip_marks.json`); otherwise it is skipped and logged. Words from the
last visit wait one visit when there are others (so the child meets them all), then the
most known letters first, then the least used.

| id | Text | When |
|---|---|---|
| `bridge_in` | Nå bygger vi broa. Hver stein er en bokstav. | station start |
| `hook_<id>` | (table above) | each word, while its picture pops up |
| `bridge_word_<id>` | (table above) | the word's sockets appear; its planks light at the measured sound onsets, all of them at the word |
| `bridge_ask` | Hvilken bokstav mangler? | each missing plank, then its `lyd_x_held` (t, b: `lyd_x`) |
| `bridge_right` | Ja! Der passet den. | every right stone (after a chime) |
| `bridge_word_done` | Ja! Der står det et ord. | a finished word that is not the last; then its letters sink into the planks |
| `bridge_next` | Broa er ikke lang nok ennå. Vi lager ett ord til! | before the next word |
| `bridge_done` | Broa er ferdig! Der står det lam. | after `lam`: the islet end of the deck is laid, the letters sink |
| `bridge_walk` | Se, lammet kommer over broa! Takk for hjelpen! | while the lamb crosses |

A wrong stone: its `lyd_y`, `sfx_tok`, then the plank's held sound again.

The bridge grows: all of today's slots are laid out from the island side (smaller planks
when there are several words, a short deck gap between words); a word's sockets appear
when its turn comes, the finished words stay as planks, and the deck reaches the islet
only when `lam` is done. Missing planks: the word's letters the child has met (at most 6
across the visit, picked word by word so every word keeps one to lay); the others lie
ready as planks.

## End

| id | Text | When |
|---|---|---|
| `end_bye` | Nå er jeg trøtt. Takk for i dag, ha det! | after the bridge, sunset; a tap starts a new day |
