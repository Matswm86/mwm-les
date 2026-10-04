# MWM Les: voice script, island 1 (Enhjørningenga)

Status: **draft for teacher approval. Nothing is recorded yet.** Replaces every line in `tools/voice_lines.tsv` once approved.
Written 2026-10-04 against `docs/SPEECH_RULES.md` (R1-R12 below = its rule numbers) and the code that plays each line (`scripts/Main.gd`, `scripts/OpeningStory.gd`, `scripts/activities/HorOgFinn.gd`, `Sandskriving.gd`, `OrdBro.gd`, `scripts/ui/ParentGate.gd`, `GrownupCard.gd`).

## How to read this script

| Mark | Meaning |
|---|---|
| `[lyd:s]` | The letter **sound** on its own clip, flat and without intonation (R2). Never the letter name. `[lyd:o]` is /u/ as in *ost*. |
| `[ord:lam]` | A whole word, said once at normal speed. |
| `[lydering:lam]` | The word sounded out slowly, one sound after the other: *l-a-m* (Levanger, "b-i-l"). |
| (sjekk) | I am not sure this is natural Norwegian. Please check. |

Four conventions that fix the old problems:
1. **A slot only comes at the very end of a line, after a short pause.** Nothing is ever recorded after a slot, so no line is a fragment glued around a sound (the old "Lyden … sover i en blomst", "Skriv … med fingeren på dugg").
2. **Lines that belong to one sound or one word are recorded whole**, one take per sound or word (for example "Sol begynner med den lyden."). Slots are used only where one frame serves all six sounds.
3. **"den / det / de / dem" always points at something named in the line just before** (R3). Where a line can be replayed later on its own (idle, Pip tapped), it names its thing instead.
4. **No "feil", no "flink", no "fantastisk".** A wrong choice gets the right model again, calmly (R10). Praise says what the child did (GDD 7).

## The story (one world, one cause)

Kaptein Hysj wants quiet so she can sleep. She puts all the letter sounds in her big jar, anchors her ship in the bay and falls asleep on deck. Without its sounds the island is grey and quiet. Pip asks the child to fetch the sounds. **Every sound the child finds flies out of the jar, back to the island, and the thing that starts with that sound appears.** Letters the child writes in the sand turn into letter stones, and the stones become the bridge. The lamb on the little island across the water wants to come over to Pip and the child, so they build the bridge out of stones that say *lam*.

What each found sound brings back (the visible event in Hør og finn):

| Sound | Word | What the child sees |
|---|---|---|
| [lyd:a] | ape | a monkey climbs into a tree |
| [lyd:s] | sol | the sun comes up and the island lights up |
| [lyd:i] | is | a big ice cream appears |
| [lyd:l] | lam | a lamb appears on the little island (it then wants to cross: Ordbroa) |
| [lyd:o] | ost | a big cheese appears |
| [lyd:m] | mus | a mouse peeks out |

Dropped on purpose: sounds asleep in flowers, the unicorn losing and regaining colours, the sea washing letters away, things "stuck" on the little island (R7, R8).

---

## Scene 0: Opening story (first launch, about 45 s)

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| op_night | Night, the island glows; each letter makes its sound in turn | (letters) | [lyd:a] [lyd:s] [lyd:i] [lyd:l] [lyd:o] [lyd:m] | No speech. The child hears that the island is full of sounds before they go (R7, R8). |
| op_hysj_1 | Hysj's ship glides in | Hysj | Hysj! For mye bråk! | 4 words (R5). Gives the cause at once (R8). |
| op_hysj_2 | Hysj lifts the jar lid | Hysj | Alle lydene skal i krukka mi. (sjekk: "skal oppi"?) | One statement, 6 words (R5, R6). "Sove i krukka" removed (R7). |
| op_theft | The letters fly into the jar, one at a time; the island turns grey | (letters) | [lyd:a] [lyd:s] [lyd:i] [lyd:l] [lyd:o] [lyd:m] | Each sound is heard as it leaves, so "the sounds" is something the child has heard (R3, R7). |
| op_hysj_3 | The island is grey, the ship drops anchor | Hysj | Sånn. Nå er det stille. (sjekk) | Short (R5). Names the result the child sees. |
| op_hysj_4 | Hysj sits down by the jar, yawns, snores | Hysj | Nå skal jeg sove. | 4 words. Explains why the jar stays in the bay where the child can see it (R7, R8). |
| op_pip_1 | Morning, Pip pops up | Pip | Hei! Jeg er Pip. | Ordriket model length (R5). |
| op_pip_2 | Pip points at the ship | Pip | Kaptein Hysj tok alle lydene. | One fact, 5 words (R5, R6). |
| op_pip_3 | Pip points at the grey island | Pip | Nå er øya grå og stille. | What the child sees (R7). |
| op_pip_4 | Pip points at the jar | Pip | Lydene er i krukka til Hysj. | Concrete place (R7). "til Hysj" instead of "hennes" (R3). |
| op_pip_5 | Pip looks at the child | Pip | Vil du hjelpe meg å hente dem hjem? | "dem" = lydene, named in the line before (R3). 8 words. |
| op_pip_6 | The ghost finger taps Pip; repeats on idle | Pip | Trykk på meg! | One instruction (R6). |

## Scene 1: Hub (the island between stations)

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| hub_hello | Every later launch, after the camera flies in | Pip | Hei! Der er du igjen. | Short greeting (R5). Replaces "Jeg er Pip" for a child who knows Pip. |
| hub_pip | Child taps Pip in the hub when no station is lit | Pip | Hei! Jeg er Pip. | (R5) |
| hub_next_find | Pip swims to the lit Hør og finn station; replayed on Pip tap | Pip | Kom! Vi henter lyder fra krukka. | "vi" = Pip and child together (R4). Same cause as the story (R8). |
| hub_next_write | Pip swims to the lit Sandskriving station | Pip | Kom! Vi skal skrive i sanden. | (R4, R5) |
| hub_next_bridge | Pip swims to the lit Ordbroa station | Pip | Se! Lammet vil over til oss. Kom! | The lamb is visible on the little island (R7). Concrete reason (R8). |
| hub_idle | 7 s idle in the hub; the ghost finger taps the lit station | Pip | Trykk der det lyser. | Self-contained, no pronoun (R3, R6). |
| hub_restore | A station is finished; the zone gets its colour back | Pip | Se! Fargene kommer tilbake. | Result the child sees (R7). The cause (sounds back) was told in the story (R8). |

## Scene 2: Hør og finn (listen and find)

### 2a. Station intro (start of every visit)

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| find_in_1 | Camera arrives; Pip points at the jar on Hysj's ship | Pip | Se! Krukka står på skipet til Hysj. | Concrete, visible (R7). 7 words. |
| find_in_2 | Straight after | Pip | Finn bokstavene. Da flyr lydene hjem. | Two short sentences, one instruction (R5, R6). Same cause (R8). |

### 2b. Letter intro (first time a letter is ever met; capital and small letter in the middle)

The letter name is said only here, once (R1).

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| intro_a | Big and small letter rise | Pip | Dette er bokstaven A. Store A og lille a. | R1 frame as requested. Name said "a". |
| intro_s | (same) | Pip | Dette er bokstaven S. Store S og lille s. | Name said "ess". |
| intro_i | (same) | Pip | Dette er bokstaven I. Store I og lille i. | Name said "i". |
| intro_l | (same) | Pip | Dette er bokstaven L. Store L og lille l. | Name said "ell". |
| intro_o | (same) | Pip | Dette er bokstaven O. Store O og lille o. | Name said "o". |
| intro_m | (same) | Pip | Dette er bokstaven M. Store M og lille m. | Name said "em". |
| intro_hear | Straight after intro_x | Pip | Hør på lyden. [lyd:x] | Whole sentence, then the sound alone (R2). |
| intro_tap | Straight after; repeats on idle with the ghost finger | Pip | Trykk på den lille bokstaven. | Names its thing, so it still makes sense when replayed alone (R3). |
| (no line) | Child taps the small letter | (letter) | [lyd:x] | The letter says its own sound (GDD 6.0). |

### 2c. One item (2-3 letters on sand tiles)

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| find_prompt | Letters are up; replayed on Pip tap and the replay button | Pip | Finn bokstaven som sier [lyd:x] | Fixed frame, sound last (R9: "Finn bokstaven som sier [s]."). |
| find_hint_1 | Hint level 1 (idle or after the first wrong tap): the right letter jumps and glows | Pip | Hør godt. [lyd:x] | Sentence, then sound (R2, its own example). |
| find_hint_2 | Hint level 2: Pip points, the ghost finger taps the right letter | Pip | Se hvor jeg peker. | One instruction (R6), tied to what the child sees (R7). |
| (no line) | Wrong letter tapped | (letter) | [lyd:y], then a soft wooden "tok" | The material corrects itself; no "feil" (R10, GDD 4.6). |
| find_wrong | First wrong tap on this item, after the letter's own sound | Pip | Hør en gang til. [lyd:x] | Repeats the right model calmly (R10, R11). Replaces "Den sa … Vi leter etter …". |
| (no line) | Right letter tapped | (letter) | [lyd:x] | Sound only, every time. |
| find_praise | Every 3rd right answer, after the letter has flown to the jar | Pip | Ja! Det var [lyd:x] | Specific and short, no inflated praise (GDD 7). |

### 2d. What the found sound brings back

Plays the **first** time each sound is found in a session: the jar lid pops, the letter flies from the jar to its spot, the thing appears. Later finds of the same sound: the thing does a small hop, no line.

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| back_a | /a/ found | Pip | Se! En ape i treet. | Concrete, picturable (R7, R12). Word starts with the sound found (R8). |
| back_s | /s/ found | Pip | Se! Sola kommer opp. | (R7, R8, R12) |
| back_i | /i/ found | Pip | Se! En stor is. | (R7, R8, R12) |
| back_l | /l/ found; the lamb appears on the little island | Pip | Se! Et lam på den lille øya. | Sets up the bridge (R8). |
| back_o | /o/ found | Pip | Se! En stor ost. | o = /u/ as in ost (R12). |
| back_m | /m/ found | Pip | Se! En mus titter fram. (sjekk) | (R7, R8, R12) |

Station end: hub_restore (Scene 1). No separate payoff line.

## Scene 3: Sandskriving (watch, then write in the sand)

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| write_in_1 | Start of every visit, the sand patch fades in | Pip | Her skriver vi i sanden. | "vi" = together (R4). 5 words. |
| write_in_2 | Straight after | Pip | Du skriver en bokstav. | One fact (R6). |
| write_in_3 | Straight after | Pip | Den blir til en stein. | "Den" = bokstav, named the line before (R3). |
| write_in_4 | Pip points at the unfinished bridge frame | Pip | Steinene bruker vi til broa. | Ties writing to the bridge, same world (R8). |
| write_watch | Before Pip draws the model | Pip | Se hvordan jeg skriver bokstaven. | Frame as requested; no letter name inside a task (R1). |
| (no line) | While each stroke is drawn | (Pip) | [lyd:x] held for the stroke | Sound alone, never inside a sentence (R2). |
| write_link_a | Model finished, after one more [lyd:a] | Pip | Ape begynner med den lyden. | "den lyden" = the sound just heard (R3). Recorded whole (convention 2). Replaces "/a/ som i ape". |
| write_link_s | (same, /s/) | Pip | Sol begynner med den lyden. | (R3, R12) |
| write_link_i | (same, /i/) | Pip | Is begynner med den lyden. | (R3, R12) |
| write_link_l | (same, /l/) | Pip | Lam begynner med den lyden. | (R3, R12) |
| write_link_o | (same, /o/) | Pip | Ost begynner med den lyden. | (R3, R12) |
| write_link_m | (same, /m/) | Pip | Mus begynner med den lyden. | (R3, R12) |
| write_turn_1 | Model has faded; empty sand | Pip | Nå er det din tur. | "du" form (R4). |
| write_turn_2 | Straight after; replayed on Pip tap and on idle | Pip | Skriv bokstaven som sier [lyd:x] | Same frame as Hør og finn (R9). Replaces "Nå du! Skriv …". |
| write_again_2 | Pass 2 (new letter only): empty sand, no model | Pip | Skriv bokstaven en gang til. | One instruction (R6). Self-contained (R3). |
| write_wait | Child touches the sand while Pip is still drawing | Pip | Se på meg først. | (R5, R6) |
| write_retry | Letter not accepted, the sand smooths | Pip | Prøv en gang til. | Calm, no "feil" (R10, R11). |
| write_hint_1 | Hint level 1: a pulsing start dot | Pip | Begynn ved prikken. | Points at something visible (R7). |
| write_hint_2 | Hint level 2: Pip writes it again | Pip | Se en gang til. | Then write_watch model, then write_turn_2. |
| write_hint_3 | Hint level 3: dotted letter to trace | Pip | Følg prikkene med fingeren. | One instruction (R6). |
| write_mirror | Letter is mirrored; the child's letter stays faint | Pip | Se! Bokstaven din snur andre veien. | Names "bokstaven din" instead of "den" (R3). Not a fail (GDD 6.1). Then write_watch + model, then write_hint_1. |
| (no line) | Letter accepted: it lifts out of the sand as a stone | (stone) | [lyd:x] | The stone says its sound. |
| write_right | Straight after | Pip | Ja! Du skrev bokstaven som sier [lyd:x] | Says what the child did (GDD 7); same frame (R9). |
| write_payoff | End of visit: the stones roll to the bridge | Pip | Se! Steinene ligger klare til broa. | Visible result (R7), same world (R8). Replaces the unicorn ribbon. |

## Scene 4: Ordbroa (the word bridge)

The lamb (or llama) stands on the little island across the water and wants to come over. The bridge is made of letter stones that together say its name. **Only two words fit this: `lam` and `lama`** (see Open question 1).

### 4a. Story per word

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| bridge_lam_1 | First bridge of a visit, word `lam`; the lamb hops on the little island | Pip | Se! Lammet står på den lille øya. | Visible (R7). 7 words. |
| bridge_lam_2 | Straight after (first time ever) | Pip | Lammet vil komme over til oss. | Concrete reason (R8). "oss" = Pip and child (R4). |
| bridge_lam_2r | Instead of bridge_lam_2 on later visits | Pip | Lammet vil over til oss igjen. | (R5, R8) |
| bridge_lama_1 | Word `lama`; the llama hops on the little island | Pip | Se! Der er en lama også. | First mention is "en lama" (R3). |
| bridge_lama_2 | Straight after | Pip | Lamaen vil også komme over. | (R5, R8) |
| bridge_build | Straight after, first bridge of a visit only | Pip | Vi bygger en bro av bokstaver. | "vi" = together (R4). |

### 4b. Pip models the word (planks light one by one)

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| bridge_hear_word | Before the child acts | Pip | Hør på ordet. [ord:lam] | Sentence, then the word on its own (R2). |
| bridge_hear_sounds | Each plank lights while its sound plays | Pip | Hør på lydene. [lydering:lam] | "Si dem i rekkefølge" (Levanger). Slots light in time with the clip. |
| bridge_word_again | Straight after | Pip | Det blir [ord:lam] | "Det" = the sounds just heard (R3). Recorded whole per word. |

### 4c. The task

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| bridge_ask | After modelling; replayed on Pip tap and the replay button | Pip | Hvilken bokstav mangler i [ord:lam]? | Reference: "Hvilken bokstav mangler for at det skal stå SOL?" (R9). Recorded whole per word. |
| bridge_drag | Straight after | Pip | Dra steinen til hullet. | One instruction (R6); the hole glows (R7). |
| (no line) | Child touches a stone / taps an empty slot | (stone) | [lyd:x] | Stones and slots say their sound (GDD 6.0). |
| bridge_hint_1 | Hint level 1: the right stone glows and bounces | Pip | Hør på lyden som mangler. [lyd:x] | Sentence, then sound (R2). |
| bridge_hint_2 | Hint level 2: the ghost hand drags the stone | Pip | Se på hånden. | (R6, R7) |
| (no line) | Wrong stone dropped | (stone) | [lyd:y], wobble, "tok", slides back | Control of error, no "feil" (R10). |
| bridge_wrong | First wrong stone on this word | Pip | Hør en gang til. [lyd:x] | Repeats the right model (R10). Same line as find_wrong, so the child learns it. |
| (no line) | Right stone placed, becomes a plank | (stone) | [lyd:x] + chime | |

### 4d. Bridge done

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| (no line) | Planks light left to right | (planks) | [lydering:lam] | Same clip as the model. |
| bridge_says | Straight after | Pip | Det står [ord:lam] | Natural "it says lam" (sjekk not needed). Recorded whole per word. |
| bridge_walk_lam | The lamb trots over the bridge | Pip | Se! Lammet går over broa. | What the child sees (R7). |
| bridge_done_lam | The lamb reaches Pip | Pip | Du bygde ordet lam. Nå er lammet her. | Informational praise (GDD 7). 8 words. |
| bridge_walk_lama | (same for lama) | Pip | Se! Lamaen går over broa. | (R7) |
| bridge_done_lama | (same for lama) | Pip | Du bygde ordet lama. Nå er lamaen her. | (GDD 7) |

## Scene 5: Pauses

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| pause_taps | Many fast random taps (disengaged); objects freeze briefly | Pip | Vent litt. Hør på meg. | Two short instructions, calm (R6, R11). Then the current prompt again. |
| pause_move_1 | Movement break from the engine | Pip | Vi tar en liten pause. | "Vi" = together (R4). |
| pause_move_2 | Straight after; Pip shakes his fins | Pip | Rist på armene med meg! (sjekk) | One concrete action (R6, R7). Replaces "ta en pust". |

## Scene 6: Read to a grown-up

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| grown_read | The card with today's words appears | Pip | Les ordene for en voksen. | One instruction (R6). Ordriket "Les ordene …". |
| (no line) | Child taps a word on the card | Pip | [ord:x] | The word whole. |
| grown_thanks | Adult holds "Voksen: Hørt!" | Pip | Takk for at du hørte på! | Spoken to the adult. |
| grown_later | Child taps "Ingen voksen nå" | Pip | Da leser du ordene neste gang. | Names "ordene" instead of "dem" (R3). |

## Scene 7: Session end (sunset)

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| end_yawn | Sunset starts | Pip | Jeg blir så søvnig. | (R5) |
| end_today | Straight after; the sound practised most today | Pip | Hør hva vi øvde på i dag. [lyd:x] | Sentence, then sound (R2). "vi" = together (R4). |
| off_a | Offline idea, when /a/ was practised most | Pip | Gap stort foran speilet og si [lyd:a] | One concrete action, one sentence. |
| off_s | (/s/) | Pip | Kryp som en slange og si [lyd:s] (sjekk) | One concrete action. |
| off_i | (/i/) | Pip | Smil stort foran speilet og si [lyd:i] | The /i/ mouth is a wide smile. |
| off_l | (/l/) | Pip | Tegn en strek på ryggen til en voksen og si [lyd:l] | 11 words, under the cap of 12. |
| off_o | (/o/) | Pip | Lag en ring med munnen og si [lyd:o] | Bokstavkongen: "når vi sier O, har jo munnen form som en ring". |
| off_m | (/m/) | Pip | Når maten smaker godt, kan du si [lyd:m] | Replaces the fragment "Si … når maten smaker godt". |
| off_gen_1 | Offline idea when no sound was practised | Pip | Klapp navnet ditt sammen med en voksen. | One action (R6). "i stavelser" dropped as too abstract for 4 (R7). |
| off_gen_2 | (same pool) | Pip | Hør etter lyder når du er ute i dag. | (R6) |
| off_gen_3 | (same pool) | Pip | Les ordene dine for en voksen i kveld. | (R6) |
| end_bye | After the offline idea; the screen goes calm | Pip | Ha det, venn! | No "come back tomorrow" pull (GDD 8.3). |

## Scene 8: Parent gate

| id | when it plays | who | line | why it follows the rules |
|---|---|---|---|---|
| gate_1 | The parent gate opens | Pip | Dette er for voksne. | (R5) |
| gate_2 | Straight after | Pip | Trykk på krysset for å gå tilbake. | Tells a child how to leave (R6, R7). |

---

## What the game must change to match this script (after approval, for the builder)

1. Opening: the ship anchors in the bay and Hysj sleeps by the jar (it does not sail away); the unicorn beat (rainbow mane, going white) is cut.
2. Hør og finn: the sleeping flower is replaced by the jar on the ship. On a right answer the letter flies from the jar to its spot, and on the first find of a sound per session the matching thing appears (2d). New props: monkey, cheese, mouse (sun, ice cream and lamb exist).
3. Sandskriving: no wave washing the letter away, no unicorn ribbon. The accepted letter-stone rolls to the bridge.
4. Ordbroa: only `lam` and `lama`; the "stuck" and "come home" lines are gone; modelling uses one `[lydering:x]` clip with a time mark per sound for the plank lights.
5. A wrong answer plays one line (`find_wrong` / `bridge_wrong`), not "Den sa … Vi leter etter …".
6. No clip sequence ever plays anything after a slot.

Old ids that go away: `den_sa`, `vi_leter`, `som_i`, `your_turn`, `write_done`, `bridge_prompt`, `bridge_done`, `bridge_listen`, `find_prompt`, `find_where`, `find_tap`, `de_sier`, `tap_small`, `story_find_1/2`, `story_write`, `stuck_*`, `build_*`, `home_*`, `payoff_*`, `next_*`, `pip_island`, `restore`, `break`, `mirror`, `off_find`, `off_write*`, `off_say*`, `off_snake`, `off_stretch`, `off_back`, `off_ring`, `off_food`, `ex_*`, `w_*` (replaced by `[ord:x]`), `ph_*` carrier sentences (replaced by real `[lyd:x]` clips).

## Open questions for the teacher

1. **Bridge words.** Only `lam` and `lama` fit "the lamb wants to come over". Both need /m/, the last of the six sounds, so the bridge station would open late. Is that fine? The other option is to also allow `is` early ("Se! Det står en is på den lille øya." / "Vi henter isen over broa."), where Pip fetches the ice cream instead of an animal walking. `sol`, `lim`, `slim` and `salami` are left out because none of them can cross a bridge.
2. **Hysj asleep on deck.** Is a sleeping, snoring captain all right for the tone, as the reason the jar stays where the child can see it?
3. **The unicorn.** It has no part in this story. Keep it as a silent animal on the island, or remove it?
4. **The grown-up card** asks for 3-5 words. With only `lam` and `lama` built, can it be filled up with `sol` and `is` (both decodable with a s i l o m)?
5. **Name pronunciation in the letter intro:** a, ess, i, ell, o, em. And `[lyd:o]` = /u/ as in *ost*. Correct for this age?
6. Lines marked (sjekk): "Alle lydene skal i krukka mi.", "Sånn. Nå er det stille.", "Se! En mus titter fram.", "Rist på armene med meg!", "Kryp som en slange og si [lyd:s]".

## Every slot clip needed

| Kind | Clips | Note |
|---|---|---|
| `[lyd:x]` short | a, s, i, l, o (= /u/), m | 6 clips, flat, no intonation (R2). |
| `[lyd:x]` held | a, s, i, l, o, m | 6 clips about 1.5 s, for the writing strokes and stone holds. All six are continuants. |
| `[ord:x]` | lam, lama, sol, is | lam/lama for the bridge; sol/is only if Q4 = yes (grown-up card). Add `is` for the bridge if Q1 = option two. |
| `[lydering:x]` | lam, lama | With a time mark at the start of each sound. Add `is` if Q1 = option two. |

Lines with a fixed word or sound inside them (letter intros, `back_*`, `write_link_*`, `bridge_lam_*`, `bridge_lama_*`, `bridge_ask`, `bridge_says`, `bridge_done_*`) are recorded as whole takes, one per sound or word. Where a line ends in `[lyd:x]`, the sentence is one take and the sound is still the shared clean clip after a short pause.
