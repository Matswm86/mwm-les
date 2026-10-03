# MWM Les / MWM Learn: Game Design Doc

Version 0.1, 2026-10-03. Status: first draft for the owner to review. Owner: game-designer. Next: graphic-designer (`docs/DESIGN.md`), then godot-android-dev.

Source tags used in this doc:
- **[src]** a published source I checked online while writing (link in Sources at the end).
- **[mem]** a published source I cite from memory; title, year and main finding are what I believe, but I did not re-read it for this doc. Verify before quoting it in public (store page, website).
- **[design]** my own design choice, not a research finding.
- **(my calc)** numbers from my own simulation script, not from a source.

---

## 1. Pitch

A calm cel-shaded 3D sea adventure where a 4-7 year old sails between islands with Pip, a small narwhal, and brings colour and life back to each island by learning the sounds of Norwegian letters, until they can read a whole story aloud to the pirate who stole the sounds.

## 2. Core loop

**Listen → touch → build → read → restore.**

1. **Listen:** Pip says a sound or word (always spoken, never written-only).
2. **Touch:** the child traces, taps or drags a letter-object (stone, shell, coin, plank).
3. **Build:** letters go together into a word (bridge, treasure chest, sky-writing).
4. **Read:** the child blends the word and picks the thing it names; the world reacts (the `sol` rises).
5. **Restore:** each finished station brings a part of the island back to colour, plants, animals and a new music layer.

The outer loop: sail to the island → choose one of 2-3 lit stations (freedom within limits) → 3-5 short tasks → part of the island comes back to life → after about 12 minutes Pip gets sleepy and the boat sails into the sunset.

---

## 3. Platform, orientation, controls

### 3.1 Orientation: landscape (break from the studio portrait default)

Decision **[design]**: landscape 1920x1080, `sensor_landscape` (both landscape directions), `stretch/mode="canvas_items"`, `stretch/aspect="expand"`, `mobile` renderer.

Why landscape is better here:
1. **Words are horizontal.** Reading runs left to right. A 5-letter word as touchable stones needs 5 x 200 px + gaps = about 1150 px; a sentence of 4 short words needs the full width. In portrait (1080 wide) `sjørøver` (8 letters) at 130 px minimum touch size fills the full width with no gaps, and sentences have to wrap. Wrapping breaks left-to-right tracking for a beginner.
2. **A 3D island reads better wide.** A third-person camera over a small island shows the path, the next station and the sea horizon (the next island) in one frame. Portrait shows mostly sky and ground.
3. **Grip.** Small children hold a phone or tablet with two hands on the short edges, like when watching video. Thumbs rest at the sides and the centre stays free for tracing. the owner's Samsung tablet is mostly used in landscape. (Observation, not a research finding.)
4. **Tracing fits.** Letter tracing uses 60% of screen height: 650 px at 1080 high. On a 6.5" phone in landscape that is about 4 cm per letter, enough for a 4-year-old's finger.

Cost: the studio template is portrait, so the builder must change `project.godot` and `export_presets.cfg` (`screen/orientation`). Tests and the capture bot run at `--resolution 1920x1080`.

### 3.2 Controls (one finger, no precision gestures, no reading needed)

| Input | Where | What it does |
|---|---|---|
| Tap on the ground | Island | The avatar walks there along the navmesh. No joystick: 4-year-olds cannot steer with twin sticks. |
| Tap on an object or animal | Island | It speaks its name with the first sound stretched (`sssel`). This is incidental listening practice and is never scored. |
| Tap on a lit station | Island | Starts that activity. Unlit stations do nothing (the lamp bobs and Pip says "ikke ennå"). |
| Tap on the sea | Hub map | The boat sails to that island (only open islands react). |
| Tap a letter-object | Activities | Plays its sound. The first tap always plays the sound and never commits an answer, except in "Hør og finn", where a tap is the answer. |
| Drag (finger down, move, up) | Activities | Moves a letter-stone or traces a stroke. Drop zones snap within 90 px. |
| Hold the finger on a letter for 0.6 s | Activities | Plays the sound again, stretched. |
| Tilt the device left/right | "Lydseiling" only | Steers the boat into one of 3 wide lanes. Tapping a lane does the same thing; tilt is a bonus, never required. |
| Tap Pip | Anywhere | Pip repeats the last instruction. This is the child's "help" button and is always visible. |
| Pause shell (top right, 130 px) | Anywhere | Opens a 2-icon pause: "keep playing" (big boat) / "stop for today" (sunset). |
| Parent icon (top left, small, low contrast) | Hub only | Opens the parent gate (section 10.3). |

All touch targets are at least 130 px (48 dp). No swipe-to-go-back, no pinch, no double-tap, no long-press-only actions. Nothing in play reacts to two fingers (that avoids accidental input on tablets).

---

## 4. Pedagogy spine

### 4.1 What the design relies on

| Principle | Source | How it shows up in the game |
|---|---|---|
| Systematic, explicit phonics beats non-systematic or no phonics for beginners; effects are largest when started early. | National Reading Panel 2000 **[mem]**; Ehri, Nunes, Stahl & Willows 2001 meta-analysis (Review of Educational Research): overall effect d about 0.41, larger in kindergarten and grade 1 **[mem, numbers unverified]** | A fixed, planned order of grapheme-phoneme pairs (section 4.3). No guessing words from pictures. |
| Phonemic awareness training works best when taught **with letters** and in short total doses. | Ehri, Nunes, Willows et al. 2001 (Reading Research Quarterly) **[mem]** | World 0 (pure sound play) is short (about 3 episodes). Letters appear from episode 2. |
| Word reading develops in phases: pre-alphabetic → partial alphabetic → full alphabetic → consolidated alphabetic. | Ehri 1995 (Journal of Research in Reading); Ehri 2005 (Scientific Studies of Reading) **[mem]** | Worlds map onto phases (section 4.4). |
| Decoding is a self-teaching mechanism: each successful decode of a new word helps store its spelling. | Share 1995 (Cognition), "self-teaching hypothesis" **[mem]** | Words are always decodable from known sounds; the child decodes them and never guesses from pictures. |
| Transparent orthographies (Norwegian is fairly transparent) let most children reach accurate basic decoding within the first school year; English is the slow outlier. | Seymour, Aro & Erskine 2003 (British Journal of Psychology) **[src]**. Norwegian results in the paper itself are unverified by me. | The content can move fast (about 30 graphemes in 6 worlds). The English pack later needs a different, slower design. |
| Blending with **connected** sounds ("sssooolll") works better than segmented sounds ("s - o - l") for beginners. | Gonzalez-Frey & Ehri 2021 (Scientific Studies of Reading), "connected phonation" **[mem, verify]** | Blending mechanic "Lydsklia" (6.4) and the first-sound order (continuants first). |
| Handwriting letters supports letter recognition more than typing or pure viewing. | Longcamp, Zerbato-Poudou & Velay 2005 (Acta Psychologica) **[mem]**; James & Engelhardt 2012 (Trends in Neuroscience and Education) **[mem]** | Every new letter starts with tracing (6.1). |
| Montessori: sandpaper letters (touch the shape while saying the sound), sounds before names, moveable alphabet (build words before reading them), three-period lesson (from Séguin), control of error, concrete → abstract, freedom within limits, prepared environment. | Montessori 1912, *The Montessori Method* **[mem]**; outcome evidence: Lillard & Else-Quest 2006 (Science) **[mem]** | Mini-games 6.1, 6.2, 6.6; control of error in every activity (4.6); station choice (2). |
| Vygotsky: zone of proximal development (ZPD), learning with a More Knowledgeable Other (MKO). | Vygotsky 1978, *Mind in Society* **[mem]** | The adaptive engine (section 5) and Pip (section 7). |
| Scaffolding has six functions: recruitment, reducing degrees of freedom, direction maintenance, marking critical features, frustration control, demonstration. | Wood, Bruner & Ross 1976 (Journal of Child Psychology and Psychiatry) **[mem]** | Hint ladder levels map onto these functions (5.4). |
| Contingent tutoring: after a failure, give more help; after a success, give less. It beat fixed strategies. | Wood & Middleton 1975; Wood, Wood & Middleton 1978 **[mem]** | Hint start level for the next item (5.4). |
| Gradual release of responsibility: I do → we do → you do. | Pearson & Gallagher 1983 **[mem]** | Pip's fading (section 7). |
| Training is fastest when the learner succeeds about 85% of the time (error about 15%). Proven for model learners; the human evidence is indirect. | Wilson, Shenhav, Straccia & Cohen 2019 (Nature Communications) **[src]** | Target success band 70-85% (5.3). I set the band lower than 85% because 4-year-olds, not models, are learning here, and to leave room for errors. **[design]** |
| Expected tangible rewards can lower later free interest in an activity (overjustification). | Lepper, Greene & Nisbett 1973 (preschoolers, "Good Player" award) **[mem]**; Deci, Koestner & Ryan 1999 meta-analysis (Psychological Bulletin) **[mem]** | No stars, coins, loot or streaks (section 8). |
| Good educational apps are active, engaged (not distracted), meaningful and socially interactive. | Hirsh-Pasek et al. 2015 (Psychological Science in the Public Interest) **[mem]** | No pop-up rewards that pull attention off the task; "read to a grown-up" moments (10.4). |
| Learning content built into the core mechanic (intrinsic integration) beats content bolted on beside the game. | Habgood & Ainsworth 2011 (Journal of the Learning Sciences) **[mem]** | Reading **is** the action (build the bridge, raise the sun), not a quiz before a reward. |
| Physical movement tied to the content helps young children learn vocabulary. | Mavilidi, Okely, Chandler, Cliff & Paas 2015 (Educational Psychology Review) **[mem]** | Embodied prompts (6.9). |
| Teaching someone else helps the teacher learn (protégé effect). | Chase, Chin, Oppezzo & Schwartz 2009 (Journal of Science Education and Technology) **[mem]** | World 6: the child teaches Kaptein Hysj to read. |
| Norwegian 1st grade practice: 1-2 letters a week, tracing, writing in the air, talking about the letter's shape, name and sound, listening for sounds in words. | Kristiansund kommune, "Lese- og skriveopplæring 1. trinn" **[src]** | Pace cap: at most 1 new sound per session (5.6), air-writing ritual (6.9). |

### 4.2 Norwegian specifics and traps

Norwegian (bokmål, spoken East Norwegian as the reference voice) has a fairly regular letter-to-sound mapping, with these traps for beginners. **[design]**, based on standard Norwegian phonology; a Norwegian reading teacher should review it (open question Q3).

| Trap | Examples | Rule in the game |
|---|---|---|
| **Letter names are not sounds.** `ess` ≠ /s/, `te` ≠ /t/. Saying names when blending gives "te-a-ka" instead of `tak`. | t, k, p, s, m | Montessori rule: **sounds only** until World 4. Pip never says a consonant letter name before then. Vowel names equal their sounds, so they are no problem. |
| **o has two sounds**: /uː/ as in `sol`, `bok`, `mor`; /ɔ/ as in `topp`, `og`, `som`. | sol vs som | World 1 teaches o = /u/ only ("o som i sol"). The /ɔ/ value comes in World 3 together with double consonants (`kopp`, `topp`), as "o's second sound". MVP word lists avoid o = /ɔ/. |
| **e has three faces**: /eː/ `se`, /æ/ before r `er`, `her`, and unstressed /ə/ at word ends `jente`, `gate`. | se, er, jente | World 2 teaches /eː/. /ə/ endings appear in World 3 words only after the child reads CVC words reliably. `er` is a sight word in World 6. |
| **Double consonant = short vowel.** | tak/takk, mat/matt, fin/finn | World 3 mini-game uses minimal pairs (`tak` roof vs `takk` thanks). |
| **Silent letters.** | d: `god`, `rød`, `land`; h in hv/hj: `hva`, `hjem`; g in gj: `gjøre`; t in `-et`: `huset`; v: `halv`, `tolv` | World 5 "blindpassasjerer" (stowaways): letters that ride on the word but say nothing. |
| **sj / skj / sk before i, y, ei, øy = /ʃ/** | `sjø`, `skje`, `ski`, `skip`, `skjorte` vs `skatt` (/sk/ before a) | World 5 (pirates): `skip` vs `skatt` is the key minimal contrast. |
| **kj / tj / k before i, y = /ç/** | `kjole`, `kiste`, `tjue`, `kino` | World 5. |
| **g before i, y = /j/; gj = /j/** | `gi`, `gjerde` | World 5. |
| **ng = /ŋ/** | `ting`, `seng` | World 5. |
| **rs, rt, rd, rn, rl** are retroflex in East Norwegian (`norsk` sounds like "nosjk"). | norsk, kort | Not taught as rules. These words are avoided in decodable lists until World 6. The dialect choice for the voice changes this (Q2). |
| **æ, ø, å** are separate letters with their own sounds. å = /oː/ (`båt`, `på`), which clashes with o = /u/. | båt vs bok | World 4. o vs å is a contrast game. |
| **Diphthongs** ei, øy, au | `hei`, `øy`, `sau` | World 4, taught as single "glide" sounds (one stone with two letters). |
| **Dialects.** There is no single spoken standard. Uvular r (West/South) vs rolled r. | r | Voice: one consistent speaker. Dialect is the owner's choice (Q2). |
| **Bokmål vs nynorsk** | `jeg`/`eg`, `ikke`/`ikkje` | MVP: bokmål. A nynorsk content pack is possible later (it is data only). |

**Lowercase first [design]:** almost all running text is lowercase, and Montessori starts with lowercase. Uppercase arrives in World 2 as "store søstre" (big sisters), needed for names such as `Mia` and `Ola`. The MVP word list therefore contains no names.

### 4.3 Sound order and why

Order rules **[design]**, built on the findings above:
1. **Continuants first** (sounds you can hold: s, m, l, r, f, n, v and all vowels), so blending can be connected: `sssooolll`.
2. **The most regular vowels first**: a and i almost never change value. o is next, limited to /u/.
3. **Picturable decodable words early**: after 5 sounds the child can read real nouns (`sol`, `is`, `lam`).
4. **Separate look-alikes and sound-alikes**: b/d (World 3, never in the same episode), m/n (2 worlds apart), o/å (2 worlds apart).
5. **Stops after continuants**: t, p, k, b, d, g cannot be stretched and are easily recorded with an added schwa ("tə").
6. **Norwegian-only letters together** in World 4, as a strong Norway theme.

| # | World | New graphemes (sound, IPA) | First decodable words (all picturable or actionable) |
|---|---|---|---|
| 1-6 | 1 | a /ɑ/, s /s/, i /i/, l /l/, o /u/, m /m/ | is, sol, lam, lama, lim, slim, mos, sola, silo, salami, sal, sil, mil, lo, los, sa, si, la, li |
| 7-12 | 2 | r /r/, f /f/, e /eː/, n /n/, u /ʉ/, v /ʋ/ + uppercase pairs | ris, rev, fin, fem, mus, sur, ull, ren, nese, fe, rose, Mia, Ola, Lise, Nora |
| 13-20 | 3 | t, p, k, h, j, b, d, g + o /ɔ/ + double consonants | tak/takk, kopp, bil, pil, katt, hatt, bok, bad, gutt, hopp!, ja |
| 21-27 | 4 | y /y/, æ /æ/, ø /ø/, å /oː/, ei, øy, au | båt, sky, by, øy, bær, sau, hei, øye, bøtte, nål |
| 28-35 | 5 | sj/skj/sk(i,y), kj/tj/k(i,y), ng, gj/g(i), silent d/h/t/v | skip vs skatt, sjø, sjørøver, kiste, kjeks, ting, seng, god, hva, hjem, huset |
| 36+ | 6 | sight words (ordbilder) that do not follow the rules or are too frequent to wait for: og, jeg, er, det, de, en, et, på, til, ikke, meg, deg, hun, han, har | sentences: `Mia har en båt.` `Hopp tre ganger!` |

c, q, w, x, z are shown in World 4 as "gjestebokstaver" (guest letters) with sound only, never drilled.

### 4.4 Stages → worlds → Ehri phases

| Stage | World | Ehri phase (target at the end of the world) | What the child can do at the end |
|---|---|---|---|
| Phonological awareness: rhyme, syllables, first sound (no letters) | 0 Lyttebukta (hub ship) | pre-alphabetic → start of partial | Clap syllables, hear rhymes, hear the first sound of a word. |
| Sound → letter (6 sounds), first CV/VC/CVC blends with continuants | 1 Enhjørningenga | partial alphabetic | Link 6 sounds to letters and blend `sol`, `lam`, `salami`. |
| More continuants, uppercase, CVCV words, first 2-word phrases | 2 Regnbuefossen | full alphabetic (simple words) | Read 2-syllable words, names, `rød rose`. |
| Stops, o /ɔ/, double consonants, consonant clusters | 3 Sprett-tårnet (superhero tower) | full alphabetic | Read short words with stops and clusters (`stopp`, `klapp`). |
| æ ø å y, diphthongs | 4 Nordlysøya | full alphabetic | Read all Norwegian vowels. |
| Spelling patterns and silent letters | 5 Sjørøverskjærene (pirate skerries) | consolidated alphabetic | Read multi-letter units as chunks (`skj`, `-ing`). |
| Sight words, sentences, short stories, comprehension | 6 Kaptein Hysjs fort | consolidated, early fluency | Read a 6-page story aloud. |

### 4.5 Three-period lesson as the backbone of every new sound

| Period | Montessori phrasing | In-game (Norwegian line) | Scored? |
|---|---|---|---|
| 1 Naming | "This is..." | Pip traces the stone with his horn: "Dette er /sss/. Som i sssol." Then the child traces it (6.1). 2-3 sounds on the table at once (the new one plus 1-2 known ones as contrast). | No |
| 2 Recognition | "Show me..." | "Vis meg /sss/!" The child taps the right stone among 2-4 (6.2). This is the longest period and mostly happens through games. | Yes |
| 3 Recall | "What is this?" | Pip holds up a stone: "Hva sier denne?" The child says it out loud (unscored, no microphone), and after 2.0 s Pip says it: "/sss/! Som i sol." The scored recall proxy is letter → picture: "Hvilken begynner med denne lyden?" (6.3). | Speaking: no. Proxy: yes. |

No microphone in v1 **[design]**: the RECORD_AUDIO permission, children's voice data under Families policy, and unreliable speech recognition on isolated child phonemes (Q6).

### 4.6 Control of error (self-correcting materials)

Every activity is built so that the material shows the error, not a judge **[design, after Montessori]**:
- A wrong stone in a bridge slot plays **its own** sound, the plank wobbles (0.4 s) and the stone slides back. The child hears that /m/ is not /s/. There is no buzzer, no red X and no "wrong".
- A wrong blend picture: the picked picture plays its name (`lam`), Pip says "Hmm, det var lam. Vi leste sssooolll", and the slide replays.
- Trace off the path: the glow simply stops following the finger until it returns. Nothing resets.
- Colours never carry right/wrong alone (colour-blind safe): right = the object comes alive (animation + sound).

---

## 5. ZPD in code: the adaptive learning engine

### 5.1 Module boundary (reusable for maths later)

```
scripts/learn_core/            # NO reading knowledge in here. Reused by maths.
  LearnerModel.gd              # per-skill BKT state, update(), predict()
  ItemSelector.gd              # picks next item + format to hit the success band
  HintLadder.gd                # contingent hint state machine
  SessionPlanner.gd            # session mix, new-skill gate, review schedule, soft end
  EvidenceLog.gd               # local append-only log (user://), never leaves device
  LearnBalance.gd              # const block below
  ContentPack.gd               # loads skills.json + items.json of one pack
scripts/activities/            # mini-game templates; take an Item, emit answered(...)
content/nb_reading/            # Norwegian reading pack (data + audio)
content/en_reading/            # later
content/nb_math/               # later (e.g. skill "number_5_subitize")
```

The contract between engine and activities (all typed GDScript):
```gdscript
# Activity -> engine
signal answered(item_id: StringName, skill_ids: Array[StringName], correct: bool,
                hint_level: int, first_attempt: bool, latency_sec: float)
signal disengaged(item_id: StringName)        # random tapping detected
# Engine -> activity
func start_item(item: Dictionary, format: Dictionary, hint_start: int) -> void
```

`skills.json` (one entry per skill, prerequisites form a graph):
```json
{"id":"gp_s","kind":"grapheme_phoneme","label":"s","prereq":[],"world":1,
 "audio":{"short":"ph_s_short.ogg","sustain":"ph_s_sustain.ogg"},
 "trace":"trace_s.json","example_word":"w_sol"}
{"id":"blend_cvc_cont","kind":"blend","prereq":["gp_s","gp_o","gp_l"],"world":1}
```
`items.json` (one entry per question; an item can exercise several skills):
```json
{"id":"w_sol","kind":"word","text":"sol","graphemes":["s","o","l"],
 "skills":["gp_s","gp_o","gp_l","blend_cvc_cont"],"picture":"pic_sol.png",
 "audio":"w_sol.ogg","activities":["lydsklia","ordbro","les_og_velg"],
 "distractors":["w_lam","w_is","w_lim"]}
```
A maths pack uses the same files with `kind:"quantity"`, `"number_word"` and so on; the engine never reads `kind`.

### 5.2 Learner model: Bayesian Knowledge Tracing per skill

BKT (Corbett & Anderson 1995 **[mem]**) keeps one number per skill: P(L) = the chance the child knows it.

```
on answer (first attempt only, weight w from hint level):
  g = 1 / choices_shown                   # guess chance
  if correct: post = pL*(1-S) / (pL*(1-S) + (1-pL)*g)
  else:       post = pL*S     / (pL*S     + (1-pL)*(1-g))
  post = post + (1-post)*T                # learning on this opportunity
  pL   = pL + w * (post - pL)             # hint-weighted update
predict P(correct) = pL*(1-S) + (1-pL)*g
```
Rules:
- **First-attempt rule:** only the first answer to an item is evidence. Later attempts on the same item are practice and are not scored.
- **Hint weight:** w = `HINT_EVIDENCE[hint_level]` (correct after a strong hint says little). A wrong answer always uses w = 1 if hint level ≤ 1, else w = 0.5.
- **Multi-skill items** (a word): the update goes to the skill the item is **testing** (the activity names it: Lydsklia tests `blend_*`, Ordbro tests each grapheme slot separately by slot).
- **Disengagement is not evidence:** 4 or more taps within 1.5 s on wrong targets → `disengaged`. No update. Pip does a frustration-control move (5.5).

What the numbers mean (my calc, `P_INIT=0.10, T=0.12, S=0.10`):

| Choices shown | Correct-in-a-row to reach P(L) ≥ 0.95 |
|---|---|
| 2 | 7 |
| 3 | 5 |
| 4 | 4 |

| P(L) | P(correct), 2 choices | 3 choices | 4 choices |
|---|---|---|---|
| 0.1 | 0.54 | 0.39 | 0.32 |
| 0.3 | 0.62 | 0.50 | 0.45 |
| 0.5 | 0.70 | 0.62 | 0.57 |
| 0.7 | 0.78 | 0.73 | 0.71 |
| 0.9 | 0.86 | 0.84 | 0.84 |

Simulated children (2000 runs each, the selector below choosing choices to stay in the band) (my calc):

| Child learning rate per attempt | Median attempts to mastery | Mean success |
|---|---|---|
| slow (0.05) | 18 | 0.65 |
| typical (0.12) | 12 | 0.73 |
| fast (0.25) | 10 | 0.79 |

Takeaway: at low P(L) the number of choices alone cannot reach 70% success. That is why a new skill starts with **scaffolding switched on** (hint start level 2, 2 choices) and fades it (5.4). A slow child sits under the band, which the step-down rule catches.

### 5.3 Item selector (keeps the child in the ZPD)

Each pick:
1. **Choose the skill** by session mix (5.6): 20% new/fragile (P(L) < 0.6), 60% practice (0.6 ≤ P(L) < 0.95, plus due reviews), 20% easy (mastered, fluency and confidence). Never the same skill 3 times in a row (interleaving).
2. **Choose the format** so predicted success lands in **0.70-0.85**:
   - knobs, in this order: number of choices (2/3/4), distractor similarity (`far`: different shape and sound class, e.g. s vs o; `near`: same class, e.g. s vs f; `twin`: known confusions, e.g. b/d, m/n, o/å), hint start level (0-2), word length (2-6 letters).
   - pick the hardest format whose predicted P(correct) ≥ 0.70; if none reaches 0.70 with 2 far choices, set hint start = 2.
3. **Rolling check** over the last 8 scored answers in this session:
   - success < 0.60 → **step down**: one knob easier (fewer choices, farther distractors, +1 hint start), and the next item is an "easy" mastered skill (a warm win).
   - success > 0.90 → **step up**: one knob harder.
   - in between: no change.
4. **3 wrong first-attempts in a row (any items)** → stop the activity gently: Pip suggests a movement break (6.9), then an easy item, then back to the plan.

### 5.4 Hint ladder (contingent scaffolding that fades)

| Level | Trigger | What happens | Wood/Bruner/Ross function |
|---|---|---|---|
| 0 | default | Prompt spoken once. Pip watches. | recruitment |
| 1 | 6 s idle, or 1st wrong | Pip repeats the prompt with the sound stretched: "Finn /sssss/". | direction maintenance |
| 2 | 2nd wrong, or 6 s more idle | The right object pulses softly (1.2 s period); the farthest distractor sinks away. | marking critical features, reducing degrees of freedom |
| 3 | 3rd wrong | Pip demonstrates: the horn traces the letter / points at the stone while saying the sound. | demonstration |
| 4 | 4th wrong | Do it together: the right stone glides halfway towards the slot; the child taps it to finish. The child always makes the final action. | frustration control |

**Fading (contingent shift, Wood & Middleton):** hint start for the next item of the same skill = max(0, highest level used last time − 1). A correct answer at level 0 keeps 0. A wrong first attempt raises the start by 1 next time (max 2). This is the code form of "fading support".

### 5.5 Frustration and step-down triggers (summary)

| Signal | Detection | Response |
|---|---|---|
| Struggling | rolling success < 0.60 over 8 | step down one knob + warm win |
| Stuck on an item | 3 wrong on one item | hint level 3-4, then the item is retired for this session |
| Losing it | 3 wrong first attempts in a row | movement break, then an easy item |
| Random tapping | ≥ 4 wrong taps in 1.5 s | no evidence logged; Pip: "Oi, skal vi ta en pust?" Objects freeze for 1.5 s, then the prompt is repeated |
| Long idle | 30 s no input | Pip waves and repeats; at 90 s the game pauses itself (pause shell) |
| Fatigue | session time ≥ soft end | Pip yawns; the session ends after the current task (5.6) |

### 5.6 Session planner, new-skill gate, review

- **New skill gate:** a new sound unlocks when every sound already introduced has P(L) ≥ 0.80 **and** at most 1 new sound has been introduced this session (exception: the first pair, a + s, comes together for the three-period contrast).
- **Mastered:** P(L) ≥ 0.95 **and** a correct, unhinted first attempt in at least 2 different sessions (retention, not just a streak).
- **Review (Leitner boxes [design]):** mastered skills come back after 1, 2, 4, 8, 16 sessions. A miss sends the skill back to box 1 and sets P(L) to 0.80 (practice, not relearning).
- **Prior knowledge fast lane (test-out):** before a "meet" lesson, the engine offers 1 item at 4 choices with no hint. If the child gets 3 out of 3 in a row, P(L) = 0.90 and the meet lesson is skipped (the tracing is kept, but shortened to 1 pass). A 7-year-old who already knows letters reaches blending in their first session.
- **Soft end:** at 12 min (parent setting 10/15/20) Pip yawns. The current task finishes, then the sunset scene plays. Nothing is ever cut mid-task.

### 5.7 Balance const block (paste into `scripts/learn_core/LearnBalance.gd`)

```gdscript
class_name LearnBalance
extends RefCounted

# BKT
const P_INIT: float = 0.10
const P_TRANSIT: float = 0.12
const P_SLIP: float = 0.10
const HINT_EVIDENCE: Array[float] = [1.0, 0.7, 0.3, 0.0, 0.0]  # weight of a CORRECT answer per hint level
const WRONG_EVIDENCE_AFTER_HINT: float = 0.5
# ZPD band
const TARGET_SUCCESS_LOW: float = 0.70
const TARGET_SUCCESS_HIGH: float = 0.85
const ROLLING_WINDOW: int = 8
const STEP_DOWN_BELOW: float = 0.60
const STEP_UP_ABOVE: float = 0.90
const WRONG_STREAK_BREAK: int = 3
# Mastery and pace
const INTRO_NEXT_P: float = 0.80
const MASTERY_P: float = 0.95
const MASTERY_SESSIONS: int = 2
const MAX_NEW_SKILLS_PER_SESSION: int = 1
const LEITNER_INTERVALS_SESSIONS: Array[int] = [1, 2, 4, 8, 16]
const REVIEW_MISS_RESET_P: float = 0.80
const TEST_OUT_STREAK: int = 3
const TEST_OUT_P: float = 0.90
const MIX_NEW: float = 0.20
const MIX_PRACTICE: float = 0.60
const MIX_EASY: float = 0.20
const MAX_SAME_SKILL_IN_A_ROW: int = 2
# Hints and idle
const IDLE_HINT_SEC: float = 6.0
const HINT_MAX: int = 4
const HINT_START_NEW_SKILL: int = 2
const IDLE_WAVE_SEC: float = 30.0
const IDLE_PAUSE_SEC: float = 90.0
const RANDOM_TAP_COUNT: int = 4
const RANDOM_TAP_WINDOW_SEC: float = 1.5
const RECALL_WAIT_SEC: float = 2.0
# Session
const SESSION_SOFT_END_SEC: float = 720.0
const SESSION_CAP_OPTIONS_SEC: Array[float] = [600.0, 900.0, 1200.0]
# Tracing
const TRACE_TOLERANCE_START: float = 0.22   # corridor half-width, fraction of letter height
const TRACE_TOLERANCE_MIN: float = 0.12
const TRACE_TOLERANCE_STEP: float = 0.02    # tighter per successful trace of that letter
const TRACE_COVERAGE_DONE: float = 0.90     # fraction of stroke arc length covered in order
const TRACE_LETTER_HEIGHT_FRAC: float = 0.60
# Drag and drop
const SNAP_RADIUS_PX: float = 90.0
const MIN_TOUCH_PX: float = 130.0
```

---

## 6. Mini-games (activity templates)

Every activity: 3-6 items, 1-3 minutes, spoken prompt only, no timer, ends on a success.

### 6.1 Sandsporing (Sand tracing), Montessori sandpaper letters
- **Setting:** wet sand on the beach; Pip draws the letter with his glowing horn.
- **Rule:** the letter fills 60% of screen height. Strokes are defined as polylines in a 0-1 box with start dot, arrow and stroke order (`trace_s.json`). The child puts a finger on the start dot (pulsing, 130 px) and drags. While the finger is inside the corridor and moving forward, the sand glows behind it and the **sustained sound plays** (`ssss`, looped for continuants; stops play once at the end of the stroke). Stroke done at 90% arc coverage. Letter done after all strokes → the letter lifts out of the sand as a stone and says its sound plus the example word ("/s/, som i sol").
- **Passes:** pass 1 Pip's horn draws it ahead of the finger (ghost), pass 2 dots only, pass 3 just the start dot. The corridor narrows by 0.02 per successful trace (0.22 → 0.12).
- **Control of error:** leaving the corridor only stops the glow. No reset, no fail.
- **Tests:** not scored (exposure + motor memory). Feeds period 1.

### 6.2 Hør og finn (Listen and find), three-period lesson, period 2
- **Setting:** shells on the beach / lanterns in the tower / coins in a chest, by world.
- **Rule:** "Vis meg /mmm/!" 2-4 letter-shells; the child taps one. Right: the shell opens, a creature pops out and plays the sound. Wrong: the shell plays its own sound and closes (control of error).
- **Scored:** yes, grapheme-phoneme skill.

### 6.3 Første lyd (First sound fishing), phonological awareness + three-period recall proxy
- **Setting:** fishing from the boat; Pip holds up a letter.
- **Rule:** 3 fish carry pictures (`sol`, `lam`, `is`); "Hvilken begynner med /sss/?" The child taps a fish; it jumps into the net, its name is said with the first sound stretched (`sssol`). In World 0 there is no letter, only the spoken sound.
- **Scored:** yes, recall proxy for the grapheme (World 1+) or first-sound skill (World 0).

### 6.4 Lydsklia (The sound slide), connected blending
- **Setting:** a rainbow slide made of letter-stones; the avatar (or a unicorn foal) sits on top.
- **Rule:** the child drags the rider down the slide with one finger. Each stone plays its sustained sound while the rider is on it, and the sounds overlap with an 80 ms crossfade, so slow sliding gives `sssooolll`. At the bottom the whole word plays at normal speed (`sol!`), then 3 pictures appear: "Hva leste vi?" The right picture comes alive (the sun rises over the island).
- **Speed control is the scaffold:** the child chooses the speed. Pip's level-3 hint is to slide down with the child.
- **Scored:** picture pick, `blend_*` skill.

### 6.5 Elkonin-skatten (Sound boxes treasure), segmenting, Elkonin boxes
- **Method:** Elkonin sound boxes (Elkonin 1963/1973 **[mem]**): push one token per sound.
- **Rule:** "Legg en mynt for hver lyd i `lam`." 3 empty boxes on a treasure chest lid; the child drags a coin into each box; each coin plays the next sound as it lands (/l/ /a/ /m/). In World 1 the boxes match the sound count (no counting error possible, it is modelling). From World 2 there is one extra box; the chest opens only when the coins match the sound count (a wrong count: the lid rattles, Pip says the word slowly again).
- **Scored:** from World 2, `segment_*` skill.

### 6.6 Ordbroa (The word bridge), Montessori moveable alphabet
- **Setting:** a gap in a path over a stream; a word-picture floats on the far side.
- **Rule:** Pip says "`sol`". 3 empty plank slots; 4-6 letter-stones (the right letters plus 1-3 distractors) in a basket. The child drags a stone into a slot; every stone plays its sound when touched. A right stone becomes a plank. A wrong stone plays its sound, wobbles and returns (control of error). When the bridge is complete the child walks across and the word is read aloud while each plank lights up left to right.
- **Montessori point:** encoding (building) a word before reading it.
- **Scored:** per slot, grapheme skill; the whole bridge for `spell_*`.

### 6.7 Lydseiling (Sound sailing), embodied listening, phone tilt
- **Rule:** the boat sails forward automatically and slowly (no speed pressure). Pip says a sound; 3 buoy-gates show letters. The child tilts the device to steer into the matching gate, or taps the gate (lanes are 33% of the screen width each). Right gate: a dolphin jump and the sound. Wrong gate: the buoy plays its sound and the boat circles back for another pass (no loss).
- **Technical:** `Input.get_accelerometer()` x-axis, dead zone ±0.15 g, full lane at ±0.35 g. The builder must verify on the owner's tablet that the accelerometer reports in the Godot 4.6 Android export (the project setting for sensors may need enabling). Parent toggle "Bevegelseskontroll" (motion controls) on/off.
- **Scored:** yes, grapheme skill (recognition).

### 6.8 Les og gjør (Read and do), comprehension, superhero commands
- **From World 3:** a word or sentence card (`hopp!`, `klapp!`, `snu deg!`). The child reads it (on their own or tapping words to hear them, which counts as hint level 1), then taps one of 3 action pictures. The superhero avatar does the action, and Pip invites the child to do it too ("Gjør det du også!"). The physical part is not scored.
- **World 6:** sentences such as `Mia har en rød båt.` → pick the matching picture of 3 (minimal differences: red/blue boat, boat/bike).
- **Scored:** picture pick, `read_word_*` / `read_sentence_*`.

### 6.9 Kroppsbokstaver and Stavelsestramp (body letters, syllable stomp), embodied rituals
- **Syllable stomp (World 0):** Pip says `en-hjør-ning`; the child taps a big drum once per syllable (scored), and Pip invites stomping along (not scored).
- **Body letters:** after a new letter is traced, Pip strikes a pose and the child copies: `i` = arms straight up and head as the dot, `o` = arms in a circle, `l` = stand tall, `s` = a snake wiggle. Sky-writing: "Skriv /s/ i lufta med superfingeren!" and the superhero cape-trail draws it in the sky. 6 s, then a big "Ferdig!" thumb button (or it auto-continues after 8 s). Never scored, because the phone cannot see the child, and pretending it can would teach that the game does not watch them.
- **Movement break** (from 5.3): "Hopp 5 ganger med meg!" Pip counts 1-5 aloud at 0.8 s per jump.
- **Safety:** prompts tell the child to put the device down before jumping ("Legg telefonen ned først!"). Shaking or jumping with the device is never asked for.

### 6.10 Ordbilder (Sight-word lanterns), World 6
- **Rule:** high-frequency irregular words light up as lanterns along the fort wall. "Finn `og`." 3-4 lanterns. Short (5 items), because they are memorised as whole words. Pip explains once: "Dette ordet jukser litt, det sier /ɔ/, ikke /u/." ("This word cheats a bit.")
- **Scored:** `sight_*` skill.

### 6.11 Lydkonserten (The sound concert), breather, free play
- Every learned sound is a shell on a rock. Tapping plays the sound with a musical note; the child can make "music" or let Pip sing a word they tap in sequence. No prompts, no scoring, ends whenever the child taps the boat. This is the breather station every 5th episode.

---

## 7. Pip, the companion (the More Knowledgeable Other)

**Who:** Pip is a small narwhal (the "unicorn of the sea", Arctic, so it fits a Norwegian game) who can float on a bubble over land. His horn glows and draws letters. He is curious and a little clumsy, never a teacher in a suit. Working name; the final name is Q1.

**Role:** Pip is the MKO who models, then does it with the child, then watches, then asks to be taught (gradual release, Pearson & Gallagher **[mem]**).

| Phase | When | Pip's behaviour |
|---|---|---|
| I do | Period 1 of each new sound | Traces the letter first, says the sound slowly, shows the mouth (a close-up of his mouth shape for /m/ (lips closed), /a/ (wide open)). |
| We do | First 3-5 items of a new skill | Hint start level 2. Pip slides down Lydsklia with the child and says the sounds along. |
| You do | P(L) ≥ 0.6 | Pip sits to the side and only reacts. Hints only on idle or error (ladder from level 0). |
| You teach | From World 5, 1 item per session; World 6 throughout | Pip "forgets": "Hmm, hva sa den nå igjen?" The child taps the right stone to teach Pip (scored like Hør og finn). In World 6 the child reads to Kaptein Hysj (protégé effect). |

Pip's language rules **[design]**:
- Every line ≤ 8 words for prompts, ≤ 12 for story. One instruction per line.
- **Praise is informational, not inflated:** "Du hørte /s/ i sol!" (what the child did), not "Fantastisk! Du er så flink!" Process praise over person praise (Mueller & Dweck 1998 **[mem]**). Max 1 praise line per 3 correct answers; the other right answers get the world reaction only.
- **After an error Pip never says "feil".** He reacts to the material ("Den sa /m/. Vi leter etter /s/").
- Pip has a small set of physical reactions (giggle, spin, yawn, "hmm" head tilt) so most feedback needs no words.

---

## 8. Motivation without extrinsic-reward traps

### 8.1 Devil's advocate: where common gamification fights Montessori (and the learning)

| Mechanic | Why studios use it | Why it hurts here |
|---|---|---|
| **Stars per level (1-3)** | Clear goal, replay value | Turns learning into a performance grade. A child who gets 1 star sees "I'm bad at this". Children replay for stars on levels they already know, which is the opposite of the ZPD. Montessori: no external grading, the work carries its own feedback. |
| **Coins, gems, loot, random chests** | A reward loop | Expected tangible rewards lower later free interest in the activity (Lepper et al. 1973 with preschoolers **[mem]**; Deci et al. 1999 **[mem]**). Random rewards are variable-ratio schedules (the slot-machine pattern). Coins make reading the tax you pay to get loot. |
| **Daily streaks, login rewards** | Retention | Loss aversion and guilt; a 5-year-old cannot control when they get the phone. The parent ends up nagging. A dark pattern for kids. |
| **Timers, speed bonuses** | Excitement | Punish slow processing, which is normal at 4-5. They add anxiety and reward guessing over decoding. |
| **Lives / energy / fail screens** | Stakes | There is no "fail" in learning to read; a fail screen teaches avoidance. Energy timers are banned by the studio rules anyway. |
| **Leaderboards, comparisons** | Social pressure | Comparison with others at 4-7 is harmful; children develop at very different paces. |
| **Pop-up celebrations (confetti on every tap)** | Juice | They pull attention off the task (Hirsh-Pasek "engaged, not distracted" **[mem]**), and praise inflation makes real feedback meaningless. |

**Devil's advocate against my own choice:**
- Montessori would say a screen is already too abstract: glass has no texture, and the sandpaper letter's value is touch. *Answer:* we keep the motor tracing, add sound to every touch, and push the body into it (6.9). We do not claim the app replaces physical materials (the parent area suggests offline play, 10.4).
- Montessori's freedom of choice vs an engine that chooses. *Answer:* "freedom within limits" means the engine prepares the environment (2-3 lit stations, all in the ZPD) and the child chooses among them, plus free play in Lydkonserten.
- Many 4-year-olds love stickers and stars, and some structure helps. *Answer:* the child gets visible, collectable progress, but the collectable is **the learning itself** (8.2), not a currency.
- World restoration is still a contingent reward. *Answer:* yes, but it is an endogenous consequence (the reading **makes** the sun rise: intrinsic integration, Habgood & Ainsworth **[mem]**). It is never spendable, never random and never lost.

### 8.2 What we use instead

1. **World restoration (the main progress signal):** each island starts grey and silent (a desaturation shader parameter, 0 = grey, 1 = full colour; ambient sound is wind only).
   - Finishing a station for the first time restores **its zone** (colour fades in over 2.5 s, plants grow, an animal returns). This is tied to effort and completion, so slow learners see progress too.
   - **Mastering a sound** adds a **music stem** to the island theme (6 sounds = 6 instruments, so the island literally sings the sounds the child knows) and makes the zone "bloom" (flowers, baby animals).
   - Nothing ever decays. An island the child stopped visiting stays as beautiful as they left it.
2. **Lydboka (The sound book):** an album with one page per learned sound. Each page shows the letter, plays the sound and the child's example words, and shows a little picture drawn from the island where they learned it. Mastered pages get a gold edge. This is the child's alphabet; they can browse it any time from the boat. It is the Montessori "work made visible".
3. **Autonomy:** choose the station order, choose the avatar look (superhero cape / pirate hat / unicorn rider; 3 options in the MVP, all free from the start), decorate a corner of the island with the restored animals.
4. **Competence made visible:** Pip's informational praise; the child reading a word out of the world itself (a sign on the restored bridge says `sol`).
5. **Relatedness:** Pip and the island characters remember the child ("Du lærte meg /l/!"); "read to a grown-up" moments (10.4).

---

## 9. Story and worlds

**Premise:** Kaptein Hysj (Captain Shush), a grumpy but not scary pirate, hates noise. She sailed the Sound Sea and put every letter sound into her big jar, so the islands went grey and silent. Pip the narwhal and the child sail out to free the sounds. Each sound freed goes back to its island. In the last world we learn why Hysj did it: she never learned to read, the letters on her treasure maps were just noise to her, and she was ashamed. The child teaches her to read, and she becomes a friend. No battles, no defeats: the "boss" in each world is a puzzle she left (a locked gate with a word on it).

Avatar: one child hero, chosen from 3 looks at the start (superhero, pirate, unicorn rider). Gender-neutral, no name typing; Pip calls the child "kaptein" or "venn".

| # | World (Norwegian / English) | Theme and set | Content | Signature moment |
|---|---|---|---|---|
| 0 | **Lyttebukta** / Listening Bay (hub, the ship) | The boat, the sea, Pip's home bay | Rhyme, syllables, first sound; no letters | Pip "wakes up" the ship's bell by clapping syllables |
| 1 | **Enhjørningenga** / Unicorn Meadow | Rolling hills, a unicorn herd that lost its colours, beaches | a s i l o m; first CVC blends | Reading `sol` makes the sun rise; the unicorns get their rainbow manes back one colour per sound |
| 2 | **Regnbuefossen** / Rainbow Falls | Waterfalls, rainbow bridges, flying unicorn foals | r f e n u v; uppercase "store søstre"; names | Building a rainbow bridge letter by letter to the foals' nest |
| 3 | **Sprett-tårnet** / Bounce Tower (superheroes) | A cloud city with a tower of superhero kids who lost their powers; their powers are the "bouncy" stop sounds | t p k h j b d g; o as /ɔ/; double consonants | Each hero's power returns when the child reads the power word (`hopp!`, `klapp!`) and does it |
| 4 | **Nordlysøya** / Northern Lights Isle | Snow, fjords, northern lights, puffins, reindeer, a sauna hut | y æ ø å, ei øy au | The northern lights return in one colour per vowel |
| 5 | **Sjørøverskjærene** / Pirate Skerries | Pirate coves, Hysj's crew of friendly, clumsy pirates, treasure maps | sj skj kj ng gj, silent letters as stowaways (`blindpassasjerer`) | `skip` vs `skatt`; finding the stowaway `d` hiding in `god` |
| 6 | **Kaptein Hysjs fort** / Captain Shush's Fort | Hysj's sea fort with the big sound jar | sight words, sentences, short stories | The child reads a 6-page story to Hysj; the jar opens and all the sounds fly home |

Total: about 36 skill groups, 6 worlds × 12-15 episodes ≈ 80 episodes ≈ 25-30 sessions of 12 min at a typical pace (my estimate, it depends entirely on the child).

---

## 10. Session, onboarding, parent area, privacy

### 10.1 Session shape

| Time | What happens |
|---|---|
| 0:00-0:20 | Boat in the bay. Pip pops up: "Hei, kaptein! Der er du!" Recap of the last sound learned: Pip plays it and the child taps the matching shell (an easy warm-up item). |
| 0:20-0:40 | Tap the island; the boat sails (8 s of sailing with the island theme playing, which is the music the child restored). |
| 0:40-11:00 | 3 episodes of about 3.5 min each: pick one of 2-3 lit stations → 3-6 items → zone restored. |
| ~12:00 | Pip yawns ("Jeg blir så søvnig…"). The current task finishes. |
| End | Sunset sail back; Pip says what they learned today ("I dag lærte du /m/, som i mus!"); Lydboka opens on today's page; the screen fades to the sleeping boat. The game quits to the home screen on the next tap or stays on the calm boat screen. |

- **Where a player stops:** the sunset scene is a natural, calm stop, never a cliffhanger built to keep them playing.
- **Why they come back:** curiosity (the next island glints on the horizon with a silhouette of what is there), their own restored island and its music, Pip ("Kommer du tilbake i morgen? Jeg vil høre /m/ igjen!"). No notifications, no streaks, no daily rewards.
- **Episodes per session:** 3 (setting range 2-5 through the session cap).

### 10.2 First 60 seconds (first launch, no text, no parent setup)

| t | Event |
|---|---|
| 0 s | No splash text, no menus. The camera glides over the sea to the boat. Pip pops out of the water and laughs. |
| 4 s | "Hei! Jeg er Pip. Trykk på meg!" A ghost finger taps Pip. |
| 8 s | The child taps Pip; Pip spins and giggles (proving "touching makes things happen"). |
| 12 s | Choose your look: 3 big avatars on the deck; each says its name when tapped ("superhelt", "sjørøver", "enhjørningrytter"); the second tap on the same one picks it. |
| 25 s | "Lyttebukta!" Pip shows the ship's bell: "Klapp med meg: Pip. Pi-ra-at." The first syllable-stomp item. |
| 45 s | The first island appears in grey on the horizon; "Den har mistet lydene sine! Trykk på øya!" |
| 55 s | Sailing. The first real activity starts at about 70 s. |

Language on first launch: Norwegian bokmål, whatever the device language (the only content pack in v1). The parent can change it later (Q4).

### 10.3 Parent gate and parent area

- **Gate:** the parent icon (top left, hub only) opens a screen with written text and a sum beyond the age group: "Foreldre: skriv svaret på 23 + 48" with a number pad (randomised two-digit sums with carry), plus "hold the button for 3 s to confirm". Three wrong answers close the gate for 60 s. A 4-7 year old cannot read the instruction or do the sum. **[design]**
- **Parent area contents:**
  - Progress: one row per sound, status `ikke startet / øver / sikker` (not started / practising / secure), last practised, and a plain-language line ("Mia kan lese ord med s, a, i, l, o, m."). No percentages, no grades.
  - Settings: session length 10/15/20 min; motion controls on/off; sound volume and Pip voice volume; written text Auto / On / Off (10.5); language (when packs exist).
  - "Read together" tips: 3 offline activities per world (draw letters in sand, sound-hunt at dinner: "find something that starts with /m/").
  - Reset progress (confirm twice).
  - Privacy statement in plain words: "Alt lagres bare på denne enheten. Ingenting sendes noe sted." (Everything stays on this device. Nothing is sent anywhere.)
- No purchases, no external links, no rating prompts, anywhere in the app (also not behind the gate).

### 10.4 "Read to a grown-up" moments [design]

Once per world (after its boss gate), Pip suggests: "Les ordet for en voksen!" ("Read the word to a grown-up!") A big card shows 3 words the child can read; there is no scoring and the child continues with the "Ferdig" thumb. This adds the social pillar without data or accounts.

### 10.5 When written instructions appear

Audio stays the main channel throughout. Text is added gradually, and only text the child can read **[design]**:
- Worlds 0-2: no instruction text at all.
- From World 3, or when 15 or more graphemes are mastered (setting `Auto`): Pip's spoken line also appears as a subtitle, karaoke-highlighted word by word in sync with the voice. Words made only of graphemes the child has mastered are shown in **full contrast and tappable** (tap = hear the word); other words are shown in lighter grey. As the child learns, more of each line turns readable, so they see their own progress in every sentence.
- World 6: for 1 line per episode, Pip asks the child to read the instruction first before he says it (a scored `read_sentence` item).
- Production need: word-level timestamps for every voiced line (forced alignment; the tool is the builder's choice, Q7).

### 10.6 Privacy and store compliance

- **No network:** the APK has no INTERNET permission and no analytics, crash reporter, ads SDK or account. All learner data is `user://learner.json` + `user://evidence.log` on the device. Data safety form: "no data collected, no data shared".
- **Google Play Families policy** (checked 2026-10-03 **[src]**): child-directed apps must not transmit device identifiers (ad ID, IMEI and so on), must not request location, and may only use approved SDKs. With no SDKs and no network we meet all of it by design.
- **GDPR for children:** no personal data is processed off the device, so no consent flow is needed. Norway's age of digital consent is 13 (Personopplysningsloven § 5) **[mem, verify]**; this is not triggered.
- **Permissions:** none, except possibly VIBRATE for haptics (an install-time "normal" permission with no data; Q8). No RECORD_AUDIO, CAMERA or location.
- **Child's name:** never asked for. Pip says "kaptein".

---

## 11. Feel (feedback for every action)

| Action | Sound | Visual | Duration | Haptic (if Q8 yes) |
|---|---|---|---|---|
| Tap any letter-object | its phoneme (short) | scale 1.0 → 1.12 → 1.0, ease-out-back | 0.25 s | 15 ms |
| Hold a letter | sustained phoneme (loop) | soft glow ring | while held | none |
| Trace on path | sustained phoneme + sand hiss | sand glow trail, 8 sparkle particles/s | while moving | 10 ms tick every 25% of the stroke |
| Trace complete | phoneme + example word | letter rises out of the sand as a stone, spin 360° | 1.2 s | 40 ms |
| Right answer | object's own sound + soft chime (pentatonic, pitch rises within an activity) | object comes alive (creature pops out, plank forms), 12 particles | 0.6 s | 30 ms |
| Wrong answer | the chosen object's own sound, then a soft wooden "tok" | wobble ±6° x 3, slide back | 0.4 s | none (no punishment through the hand) |
| Bridge / word complete | the word read once, left-to-right light-up per plank | walk-across animation | 1.5 s + 0.35 s per letter | 50 ms |
| Lydsklia sliding | overlapping sustained phonemes, 80 ms crossfade | rider slides; stones light up under it | child-controlled | 10 ms per stone |
| Zone restored | island music stem fades in | colour radial wipe from the station, plants grow (scale 0 → 1, stagger 0.05 s) | 2.5 s | 60 ms |
| Sound mastered | the new instrument stem joins + Pip's "Du kan /s/!" | zone bloom, butterflies, Lydboka page gets a gold edge | 3.0 s | 80 ms |
| Hint level 2 pulse | none | target emission pulse, 1.2 s period | until answered | none |
| Pip idle | rare hum | bob 4 px, blink every 3-6 s | loop | none |
| Movement break | Pip counts aloud | Pip jumps with the count | 0.8 s per count | none |

Audio mix: voice always on top (music ducks 8 dB under any voice line, 0.15 s attack, 0.4 s release). Phonemes are never covered by SFX: SFX starts 0.1 s after the phoneme ends.

---

## 12. Progression table: World 1 (MVP)

"Episode" = 1 activity station visit (about 3.5 min). Episodes unlock by the gate in 5.6, not by count, so this is the **typical** order and pace. There is no fail; the "target error" column is the designed error rate in the ZPD band.

| Ep | New element | Activities | Target time | Target error rate (first attempts) |
|---|---|---|---|---|
| 1 | Rhyme + syllables (World 0, no letters) | Stavelsestramp, Første lyd (spoken) | 3 min | 15-25% |
| 2 | First sound pair a + s (period 1) | Sandsporing a, s; body letters | 3 min | not scored |
| 3 | a/s recognition and recall | Hør og finn, Første lyd (`sol`, `ape`) | 3.5 min | 20-30% |
| 4 | Blending idea: `sa` (2 sounds) | Lydsklia, Elkonin (modelled) | 3.5 min | 15-30% |
| 5 | **Breather** | Lydkonserten, restore the beach | 2 min | none |
| 6 | i | Sandsporing, Hør og finn (3 choices) | 3.5 min | 15-30% |
| 7 | Building words: `is`, `si` | Ordbroa (2 slots), Lydsklia | 3.5 min | 15-30% |
| 8 | l + first CVC: `sil`, `sal`, `lim` | Sandsporing, Lydsklia, Lydseiling | 4 min | 15-30% |
| 9 | o (/u/): `sol`, `lo`, `los`, `silo` | Sandsporing, Lydsklia (the sun rises) | 4 min | 15-30% |
| 10 | **Breather** | Lydkonserten, decorate the meadow, Lydboka | 2 min | none |
| 11 | m: `lam`, `mil`, `mos`, `slim` | Sandsporing, Ordbroa (3 slots), Første lyd | 4 min | 15-30% |
| 12 | Longer words: `lama`, `sola`, `salami` | Lydsklia (4-6 stones), Ordbroa | 4 min | 20-30% |
| 13 | **Island gate** (Hysj's locked gate shows `sol`, `is`, `lam`) + "read to a grown-up" | Les og velg (3 words), grown-up card | 3 min | 15-25% |
| 14+ | Review loop until all 6 sounds are mastered (5.6) | child picks from 3 lit stations | 3.5 min each | 15-30% |

MVP decodable word list (o = /u/ only, no names, no doubles): `is, sa, si, la, li, lo, sal, sil, lim, mil, mos, los, lam, sol, slim, sola, silo, lama, salami`. Picture words for Første lyd, 4 per sound (first sound must be the taught value): a: `ape, and, ananas, appelsin`; s: `sol, sel, sau, sild`; i: `is, igle, iglo` (only 3 safe); l: `lam, løve, lampe, lue`; o (/u/): `ost, oter` (only 2 safe, see Q3); m: `mus, melk, måne, mamma`. **[design, needs a native-teacher check]**

---

## 13. MVP scope (first playable slice)

**In:**
- Hub ship + World 0 lite (2 activities) + World 1 Enhjørningenga (one island, 6 sounds a s i l o m, 13 episodes + review loop).
- Activities: Sandsporing, Hør og finn, Første lyd, Lydsklia, Ordbroa, Lydkonserten, body-letter ritual, movement break. (Lydseiling and Elkonin are optional stretch goals.)
- `learn_core/` engine complete (BKT, selector, hint ladder, planner, local save) with headless unit tests that replay scripted answer sequences and check P(L), hint starts and step-down, mirroring the simulation numbers in 5.2.
- Pip with 4 animations (idle, talk, giggle-spin, yawn) + horn-tracing.
- 3 avatar looks, island restoration (desaturation shader + 6 music stems), Lydboka (6 pages).
- Parent gate + parent area (progress, session length, motion, reset, privacy text).
- Norwegian bokmål audio only; landscape; no network.

**Audio production for the MVP (human voice, the hard dependency):**

| Clip set | Count | Notes |
|---|---|---|
| Isolated phonemes, short | 6 | ~300-450 ms each. Stops later: no schwa ("t", not "tə"). |
| Phonemes, sustained loopable | 6 | 2.0 s, steady pitch, loop points marked (continuants only) |
| Alternate takes | 12 | 2 extra of each short phoneme, for natural variation |
| Decodable words, normal | 19 | list in 12 |
| Decodable words, stretched (connected) | 19 | `sssooolll` style, ~2.5 s |
| Picture words, first sound stretched | ~24 | `sssel` |
| Pip lines | ~150 | prompts, praise, hints, story |
| Story / Hysj lines | ~20 | |
| **Total** | **~255** | about 2-3 hours of studio time with retakes (my estimate) |

Recording spec **[design]**: 48 kHz mono WAV, a quiet room, the same mic distance throughout, edited to -18 LUFS integrated, peaks ≤ -1 dBFS, exported as Ogg Vorbis q5. One speaker for Pip, one for Hysj. **TTS cannot produce isolated phonemes reliably** (it adds vowels and clips stops), so phonemes and teaching words must be human. TTS (for example a Norwegian Piper voice **[mem, verify it exists and its licence]**) is allowed only as a placeholder during development, and every placeholder file is named `tts_*.ogg` so QA can block a release that still contains one.

**Deferred:** Worlds 2-6; English content pack (it needs its own phonics order, SATPIN-style, and a separate design); nynorsk; maths pack; uppercase; Lydseiling tilt (if not done); Elkonin scoring; Les og gjør; sight words; karaoke text; microphone / speech features; multiple child profiles; haptics (if Q8 is no); Play Store release (checklist in `game-studio/docs/play-store-checklist.md`).

**MVP "done" test for game-qa:** a 4-year-old (the test child, if available) plays 3 sessions without an adult reading anything to them, and the parent area shows at least 3 sounds as "øver" or "sikker". The headless engine tests pass. 60 fps on the PerfOverlay on the owner's tablet (calm game: 30 fps allowed per DESIGN.md if needed).

---

## 14. Open questions for the owner

1. **Companion:** is a narwhal called Pip right, or do you want a unicorn foal, a parrot (pirate theme, and parrots repeat sounds) or another animal? Do you want a name?
2. **Voice and dialect:** whose voice records the phonemes and Pip (you, a family member, a hired speaker)? Which dialect: East Norwegian "standard" with rolled r, or your own dialect? The r sound and retroflexes depend on this.
3. **Teacher review:** can a Norwegian 1st-grade teacher or special-ed teacher check the sound order (4.3), the o = /u/ choice for World 1, and the picture-word list in 12 (especially safe o-words: I only trust `ost` and `oter`)?
4. **English:** does "English selectable" mean (a) Pip speaks English while still teaching Norwegian letters (for non-Norwegian parents and children in Norway), or (b) a full English reading course (a separate content pack and design, deferred)? I assumed (b) later and only Norwegian in v1.
5. **Orientation:** OK to break the studio portrait default and go landscape (3.1)?
6. **Microphone:** no speech recognition in v1 (permission, children's voice data, poor accuracy on child phonemes). Confirm, or do you want it researched as a later option?
7. **Karaoke text timing:** OK to defer word-timed subtitles to World 3 (post-MVP)?
8. **Haptics:** OK to add the VIBRATE permission (install-time, no data, no prompt), or keep the app at zero permissions?
9. **Profiles:** one child per device in v1, or do siblings need 2-3 profiles from the start?
10. **Bokmål only**, or nynorsk too (it is a data pack, but it doubles the recording work)?
11. **Store:** is this a sideload/family app first, or aimed at Google Play (Families program, Teacher Approved) from the start?

---

## Sources

Checked online for this draft:
- [Wilson et al. 2019, The Eighty Five Percent Rule for optimal learning, Nature Communications](https://pmc.ncbi.nlm.nih.gov/articles/PMC6831579)
- [Seymour, Aro & Erskine 2003, Foundation literacy acquisition in European orthographies](https://discovery.dundee.ac.uk/en/publications/foundation-literacy-acquisition-in-european-orthographies/)
- [Kristiansund kommune, Lese- og skriveopplæring 1. trinn (PDF)](https://www.kristiansund.kommune.no/_f/i09d8ca8c-dfcd-44d1-be7a-e2bc0759829a/lese-og-skriveopplaring-1trinn.pdf)
- [Google Play Families policy](https://support.google.com/googleplay/android-developer/answer/9893335)

Cited from memory, not re-read (verify before public use): National Reading Panel 2000; Ehri, Nunes, Stahl & Willows 2001; Ehri, Nunes, Willows et al. 2001; Ehri 1995, 2005; Share 1995; Gonzalez-Frey & Ehri 2021; Longcamp et al. 2005; James & Engelhardt 2012; Montessori 1912; Lillard & Else-Quest 2006; Vygotsky 1978; Wood, Bruner & Ross 1976; Wood & Middleton 1975; Wood, Wood & Middleton 1978; Pearson & Gallagher 1983; Corbett & Anderson 1995; Elkonin 1963/1973; Lepper, Greene & Nisbett 1973; Deci, Koestner & Ryan 1999; Mueller & Dweck 1998; Hirsh-Pasek et al. 2015; Habgood & Ainsworth 2011; Mavilidi et al. 2015; Chase et al. 2009; Personopplysningsloven § 5.
