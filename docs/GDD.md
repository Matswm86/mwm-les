# MWM Les / MWM Learn: Game Design Doc

Version 0.2, 2026-10-03. Status: second draft for the owner to review. Owner: game-designer. Next: graphic-designer (`docs/DESIGN.md`), then godot-android-dev.

**Changelog 0.1 → 0.2** (applies section 4 of `docs/RESEARCH.md`):
1. Tracing replaced by "watch then write" (6.1); adult co-play is now core: a daily "read to a grown-up" step, a parent script and a paper handwriting prompt (10.4, 10.3).
2. Added syllable chunking (World 2), explicit cluster and multi-letter grapheme content (4.3.1), a no-speed-timer rule, a session cap with offline follow-ups; adaptivity is kept for pacing only.
3. Citations corrected against RESEARCH.md (Deci instead of Dweck, Randolph 2023 for Montessori, Elkonin 1973), evidence-strength tags added; bokmål only, landscape and the placeholder voice are decided.

Source tags used in this doc:
- **[src]** a published source checked online (full list and status in `docs/RESEARCH.md`).
- **[design]** my own design choice, not a research finding.
- **(my calc)** numbers from my own simulation script, not from a source.

Evidence-strength tags on pedagogy claims: **meta-analysis** / **RCT** (randomised or group-randomised trial) / **small trial** (one study, small n or a single school) / **guidance** (curriculum, official or teacher-practice guidance) / **theory** (a model or framework, not an outcome test) / **extrapolated** (evidence from another age, subject or population, applied here by me).

---

## 1. Pitch

A calm cel-shaded 3D sea adventure where a 4-7 year old sails between islands with Pip, a small narwhal, and brings colour and life back to each island by learning the sounds of Norwegian letters, until they can read a whole story aloud to the pirate who stole the sounds.

## 2. Core loop

**Listen → touch → build → read → restore → read to a grown-up.**

1. **Listen:** Pip says a sound or word (always spoken, never written-only).
2. **Touch:** the child writes a letter from memory in the sand, taps or drags a letter-object (stone, shell, coin, plank).
3. **Build:** letters go together into a word (bridge, treasure chest, sky-writing).
4. **Read:** the child blends the word and picks the thing it names; the world reacts (the `sol` rises).
5. **Restore:** each finished station brings a part of the island back to colour, plants, animals and a new music layer.
6. **Read to a grown-up:** at the end of every session the child reads the words they built today to an adult (10.4).

The outer loop: sail to the island → choose one of 2-3 lit stations (freedom within limits) → 3-5 short tasks → part of the island comes back to life → at about 11 minutes the read-to-a-grown-up card → Pip gets sleepy, suggests one thing to do away from the screen, and the boat sails into the sunset.

The app is designed to be used **with** an adult nearby, not as a solo tutor. The best evidence for letter-sound games shows no overall effect on word reading, and a moderate effect in studies where an adult was closely involved (McTigue et al. 2020, **meta-analysis**, see 4.1). Expected learning effects from the app are small; the adult step is the part most likely to make a difference.

---

## 3. Platform, orientation, controls

### 3.1 Orientation: landscape (break from the studio portrait default)

Decision **[design]**, accepted by the owner (Q5 resolved): landscape 1920x1080, `sensor_landscape` (both landscape directions), `stretch/mode="canvas_items"`, `stretch/aspect="expand"`, `mobile` renderer.

Why landscape is better here:
1. **Words are horizontal.** Reading runs left to right. A 5-letter word as touchable stones needs 5 x 200 px + gaps = about 1150 px; a sentence of 4 short words needs the full width. In portrait (1080 wide) `sjørøver` (8 letters) at 130 px minimum touch size fills the full width with no gaps, and sentences have to wrap. Wrapping breaks left-to-right tracking for a beginner.
2. **A 3D island reads better wide.** A third-person camera over a small island shows the path, the next station and the sea horizon (the next island) in one frame. Portrait shows mostly sky and ground.
3. **Grip.** Small children hold a phone or tablet with two hands on the short edges, like when watching video. Thumbs rest at the sides and the centre stays free for writing. The owner's Samsung tablet is mostly used in landscape. (Observation, not a research finding.)
4. **Writing fits.** The letter writing area uses 60% of screen height: 650 px at 1080 high. On a 6.5" phone in landscape that is about 4 cm per letter, enough for a 4-year-old's finger.

Cost: the studio template is portrait, so the builder must change `project.godot` and `export_presets.cfg` (`screen/orientation`). Tests and the capture bot run at `--resolution 1920x1080`.

### 3.2 Controls (one finger, no precision gestures, no reading needed)

| Input | Where | What it does |
|---|---|---|
| Tap on the ground | Island | The avatar walks there along the navmesh. No joystick: 4-year-olds cannot steer with twin sticks. |
| Tap on an object or animal | Island | It speaks its name with the first sound stretched (`sssel`). This is incidental listening practice and is never scored. |
| Tap on a lit station | Island | Starts that activity. Unlit stations do nothing (the lamp bobs and Pip says "ikke ennå"). |
| Tap on the sea | Hub map | The boat sails to that island (only open islands react). |
| Tap a letter-object | Activities | Plays its sound. The first tap always plays the sound and never commits an answer, except in "Hør og finn", where a tap is the answer. |
| Drag (finger down, move, up) | Activities | Moves a letter-stone or draws a stroke in the sand. Drop zones snap within 90 px. |
| Hold the finger on a letter for 0.6 s | Activities | Plays the sound again, stretched. |
| Tilt the device left/right | "Lydseiling" only | Steers the boat into one of 3 wide lanes. Tapping a lane does the same thing; tilt is a bonus, never required. |
| Tap Pip | Anywhere | Pip repeats the last instruction. This is the child's "help" button and is always visible. |
| Pause shell (top right, 130 px) | Anywhere | Opens a 2-icon pause: "keep playing" (big boat) / "stop for today" (sunset). |
| Parent icon (top left, small, low contrast) | Hub only | Opens the parent gate (section 10.3). |

All touch targets are at least 130 px (48 dp). No swipe-to-go-back, no pinch, no double-tap, no long-press-only actions. Nothing in play reacts to two fingers (that avoids accidental input on tablets).

---

## 4. Pedagogy spine

### 4.1 What the design relies on

Every claim carries an evidence-strength tag (legend at the top). Full citations and their verification status: `docs/RESEARCH.md`.

| Principle | Source | Evidence | How it shows up in the game |
|---|---|---|---|
| Systematic, explicit phonics beats non-systematic or no phonics for beginners; effects are larger when started early. | Ehri, Nunes, Stahl & Willows 2001 (66 comparisons, d = 0.41), via National Reading Panel 2000 **[src]** | meta-analysis | A fixed, planned order of grapheme-phoneme pairs (4.3). No guessing words from pictures. |
| Phonemic awareness training works best **with letters**, on 1-2 skills, in short total doses (5-18 hours). | Ehri, Nunes, Willows et al. 2001 (52 studies, d = 0.53 on reading) **[src]**; Språkløyper: oral-only blending is "lite hensiktsmessig" **[src]** | meta-analysis + guidance | World 0 (pure sound play) is short (1-2 episodes, shortened in 0.2). Letters appear from episode 2. |
| Letter sounds, not letter names, when blending. | Lesesenteret, Språkløyper **[src]** | guidance | Sounds only until World 4 (4.2). |
| Word reading develops in phases: pre-alphabetic → partial → full → consolidated alphabetic. | Ehri 1995; Ehri 2005 **[src]** | theory | Worlds map onto phases (4.4). |
| Each successful decode of a new word helps store its spelling (self-teaching). | Share 1995 **[src]** | theory | Words are always decodable from known sounds. |
| Norwegian is fairly transparent, but has complex syllables (clusters, closed syllables, sk/skj/kj, ng). Finnish is alone in the simplest group, so Finnish pacing will not transfer fully. | Seymour, Aro & Erskine 2003 **[src]** | extrapolated (my inference from the paper's classification) | Explicit cluster and multi-letter content (4.3.1); Norwegian pacing planned slower than Finnish practice. The English pack later needs its own, slower design. |
| Blending with **connected** sounds ("sssooolll") beats segmented sounds ("s - o - l"); continuants first, then stops. | Gonzalez-Frey & Ehri 2021 (kindergarteners, n = 38) **[src]**; Språkløyper **[src]** | small trial + guidance | Lydsklia (6.4) and the continuant-first order (4.3). |
| Syllables are a later strategy for long words; hyphenating displayed words gave grade 1-2 readers no benefit for new words. | Lyytinen, Richardson & Aro 2019; Språkløyper **[src]**; Häikiö & Luotojärvi 2021 (eye-tracking) **[src]** | guidance + small trial | Syllable chunking for two-syllable words in World 2 (6.4); displayed words are never hyphenated. |
| Writing letters **from memory** recruits the 5-year-old reading circuit; tracing and typing did not. Handwriting beat typing only in the older children of a 3-5 year sample. | James & Engelhardt 2012 **[src]**; Longcamp, Zerbato-Poudou & Velay 2005 **[src]** | small trial | "Watch then write" (6.1): Pip models, the model fades, the child writes from memory. A full trace overlay is only the last hint. Paper handwriting prompt in the parent area (10.3). |
| A letter-sound game (GraphoGame) showed no overall effect on word reading (g = -0.02, 19 studies) and g = 0.48 in studies with high adult interaction. Large independent trials found no effect (England, 398 pupils) or small effects (France, N = 921, 0.18-0.27). | McTigue, Solheim, Zimmer & Uppstad 2020 **[src]**; EEF/NFER trial; Lassault et al. 2022 **[src]** | meta-analysis + RCT | Adult co-play is core: daily read-to-a-grown-up step and a parent script (10.4). Expected effects stated as small. |
| An adaptive and a non-adaptive version of the computer part of a teacher-led programme worked equally well. | Solheim et al. 2018 (On Track, 13 schools) **[src]** | RCT | The adaptive engine (section 5) is kept **for pacing only**; no claim that adaptivity itself causes learning. |
| Bayesian Knowledge Tracing as the learner model. | Corbett & Anderson 1995 **[src]** | theory (no child-reading evidence) | Section 5.2. |
| Zone of proximal development; learning with a More Knowledgeable Other. | Vygotsky 1978 (unverified) | theory | Pacing band (5.3) and Pip (section 7). |
| Scaffolding has six functions: recruitment, reducing degrees of freedom, direction maintenance, marking critical features, frustration control, demonstration. | Wood, Bruner & Ross 1976 **[src]** | theory | Hint ladder (5.4). |
| Contingent tutoring: more help after a failure, less after a success. | Wood & Middleton 1975; Wood, Wood & Middleton 1978 (unverified) | small trial | Hint start level for the next item (5.4). |
| Gradual release: I do → we do → you do. | Pearson & Gallagher 1983 (a comprehension model) **[src]** | theory, extrapolated | Pip's fading (section 7). |
| Training is fastest at about 85% success. Shown for model learners; human evidence is indirect. | Wilson, Shenhav, Straccia & Cohen 2019 **[src]** | extrapolated | Target band 70-85% (5.3); set lower for 4-year-olds **[design]**. |
| Expected tangible rewards lower later free interest; tangible rewards are worse for children; positive informational feedback raises intrinsic motivation. | Lepper, Greene & Nisbett 1973 (preschoolers) **[src]**; Deci, Koestner & Ryan 1999 (128 studies) **[src]** | small trial + meta-analysis | No stars, coins, loot or streaks (section 8); informational praise (section 7). |
| Praise type (process vs person). | Mueller & Dweck 1998 failed a close replication (Li & Bates 2019, n = 624) **[src]** | not used as support | Praise rule rests on Deci 1999 instead. |
| Good educational apps are active, engaged, meaningful and socially interactive. | Hirsh-Pasek et al. 2015 **[src]** | theory (framework) | No attention-pulling pop-ups; the grown-up step (10.4). |
| Content built into the core mechanic (intrinsic integration) beats content bolted on. | Habgood & Ainsworth 2011 (maths, ages 7-11) **[src]** | extrapolated | Reading **is** the action (build the bridge, raise the sun). |
| Montessori education overall shows a modest academic benefit (32 studies, g = 0.24); individual materials (sandpaper letters, moveable alphabet, three-period lesson) are not tested on their own. | Randolph et al. 2023 **[src]**; Lillard & Else-Quest 2006 (one school, weak) **[src]**; Montessori 1912 (unverified) | meta-analysis (education overall); materials = theory | The materials are **design inspiration** only: mini-games 6.1, 6.2, 6.6; control of error (4.6); station choice (2). |
| Movement tied to content helped preschoolers learn foreign-language vocabulary. | Mavilidi et al. 2015 **[src]** | extrapolated | Movement prompts (6.9) are for **engagement only**; no claim that they teach letter sounds. |
| Teaching someone else helps the teacher learn (protégé effect). | Chase, Chin, Oppezzo & Schwartz 2009 (unverified) | extrapolated | World 6: the child teaches Kaptein Hysj to read. |
| Accuracy before speed; speed-based word apps only "med omhu, og kun i korte sekvenser". | Språkløyper **[src]** | guidance | **No speed timers anywhere** (rule in 8.3). |
| Reading policy tied to "mindre skjerm, mer lek" (less screen, more play). | Lesekommisjonen mandate **[src]** | guidance | Session cap (5.6) and one offline follow-up per session (10.1). |
| Norwegian 1st grade: 1-2 letters a week, tracing, writing in the air, talking about the letter's shape, name and sound, listening for sounds (we keep air-writing but replace tracing with writing from memory, row above). Udir aims after grade 2 include blending letter sounds into words in reading and writing, and handwriting. | Kristiansund kommune 1. trinn plan **[src]**; Udir Norwegian curriculum (NOR01-06) **[src]** | guidance | Pace cap: at most 1 new sound per session (5.6); air-writing ritual (6.9); paper handwriting prompt (10.3). |

### 4.2 Norwegian specifics and traps

Norwegian (bokmål, spoken East Norwegian as the reference voice) has a fairly regular letter-to-sound mapping, with these traps for beginners. **[design]**, based on standard Norwegian phonology; a Norwegian reading teacher should review it (open question Q3).

| Trap | Examples | Rule in the game |
|---|---|---|
| **Letter names are not sounds.** `ess` ≠ /s/, `te` ≠ /t/. Saying names when blending gives "te-a-ka" instead of `tak`. | t, k, p, s, m | Montessori rule: **sounds only** until World 4. Pip never says a consonant letter name before then. Vowel names equal their sounds, so they are no problem. |
| **o has two sounds**: /uː/ as in `sol`, `bok`, `mor`; /ɔ/ as in `topp`, `og`, `som`. | sol vs som | World 1 teaches o = /u/ only ("o som i sol"). The /ɔ/ value gets its own explicit station in World 3, "To o-er" (4.3.1), together with double consonants (`kopp`, `topp`), as "o's second sound". MVP word lists avoid o = /ɔ/. |
| **e has three faces**: /eː/ `se`, /æ/ before r `er`, `her`, and unstressed /ə/ at word ends `jente`, `gate`. | se, er, jente | World 2 teaches /eː/. /ə/ endings appear in World 3 words only after the child reads CVC words reliably. `er` is a sight word in World 6. |
| **Double consonant = short vowel.** | tak/takk, mat/matt, fin/finn | World 3 mini-game uses minimal pairs (`tak` roof vs `takk` thanks). |
| **Silent letters.** | d: `god`, `rød`, `land`; h in hv/hj: `hva`, `hjem`; g in gj: `gjøre`; t in `-et`: `huset`; v: `halv`, `tolv` | World 5 "blindpassasjerer" (stowaways): letters that ride on the word but say nothing. |
| **sj / skj / sk before i, y, ei, øy = /ʃ/** | `sjø`, `skje`, `ski`, `skip`, `skjorte` vs `skatt` (/sk/ before a) | World 5 (pirates), explicit station (4.3.1): `skip` vs `skatt` is the key minimal contrast. |
| **kj / tj / k before i, y = /ç/** | `kjole`, `kiste`, `tjue`, `kino` | World 5. |
| **g before i, y = /j/; gj = /j/** | `gi`, `gjerde` | World 5. |
| **ng = /ŋ/** | `ting`, `seng` | World 5, explicit station (4.3.1). |
| **rs, rt, rd, rn, rl** are retroflex in East Norwegian (`norsk` sounds like "nosjk"). | norsk, kort | Not taught as rules. These words are avoided in decodable lists until World 6. The dialect choice for the voice changes this (Q2). |
| **æ, ø, å** are separate letters with their own sounds. å = /oː/ (`båt`, `på`), which clashes with o = /u/. | båt vs bok | World 4. o vs å is a contrast game. |
| **Diphthongs** ei, øy, au | `hei`, `øy`, `sau` | World 4, taught as single "glide" sounds (one stone with two letters). |
| **Dialects.** There is no single spoken standard. Uvular r (West/South) vs rolled r. | r | Voice: one consistent speaker. Placeholder: Microsoft Finn (nb-NO); the owner picks the final voice (Q2). |
| **Bokmål vs nynorsk** | `jeg`/`eg`, `ikke`/`ikkje` | Bokmål only (decided by the owner, Q10 resolved). |

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

### 4.3.1 Clusters and multi-letter graphemes (explicit content, new in 0.2)

Norwegian has complex syllables that Finnish does not (Seymour, Aro & Erskine 2003, **extrapolated**; Språkløyper, **guidance**). These get their own stations and skills instead of being left to come "for free". **[design]**

| World | Station (Norwegian / English) | Skill ids | Content | Activities used |
|---|---|---|---|---|
| 3 | **To o-er** / Two o's | `gp_o_short` | o = /ɔ/ next to o = /u/: `sol`/`som`, `bok`/`kopp`, `mor`/`topp`. A sorting game: two baskets, one with the sun picture (/u/), one with a cup (/ɔ/). Pip's rule line: "o kan si /u/ og /ɔ/. Prøv begge!" | Hør og finn (sort variant), Lydsklia |
| 3 | **Klyngebrygga** / Cluster Pier | `cl_st`, `cl_sk`, `cl_sp`, `cl_kl`, `cl_tr`, `cl_sl` | Two consonants, two sounds, blended without a vowel between: `stopp`, `skatt`, `spa`, `klapp`, `tre`, `slim`. Each consonant stays its own stone; the slide has no gap between them. | Lydsklia, Ordbroa |
| 5 | **Skjærkista** / Skerry Chest | `gp_sj`, `gp_skj`, `gp_sk_front` | sj, skj and sk before i/y/ei/øy all say /ʃ/; sk before a/o/u/å says /sk/. Key pairs: `skip`/`skatt`, `ski`/`sko`, `sjø`, `skje`. | Hør og finn, Ordbroa, Lydsklia |
| 5 | **Kjeks-kjøkkenet** / Biscuit Galley | `gp_kj`, `gp_tj`, `gp_k_front` | kj, tj and k before i/y say /ç/: `kjeks`, `kiste`, `tjue`. | Hør og finn, Ordbroa |
| 5 | **Ng-grotta** / Ng Cave | `gp_ng` | ng = one sound /ŋ/: `ting`, `seng`, `sang`, `lang`. | Lydsklia, Ordbroa |

Rules:
- **A multi-letter grapheme is one stone** with 2-3 letters printed on it (like the diphthongs in World 4), plays one sound and fills one Ordbroa slot. A cluster is **two** stones that blend.
- Each grapheme or cluster above is a skill in the engine and goes through the same new-skill gate (at most 1 new per session, 5.6).
- **Norwegian pacing is slower than Finnish:** Worlds 3 and 5 get 4 more episodes each than the 0.1 draft (World 3: 16-19, World 5: 16-19). No content is skipped to keep a Finnish-style pace.

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
| 1 Naming | "This is..." | Pip writes the letter in the sand with his horn, stroke by stroke, saying the sound: "Dette er /sss/. Som i sssol." The model fades and the child writes it from memory (6.1). 2-3 sounds on the table at once (the new one plus 1-2 known ones as contrast). | No |
| 2 Recognition | "Show me..." | "Vis meg /sss/!" The child taps the right stone among 2-4 (6.2). This is the longest period and mostly happens through games. | Yes |
| 3 Recall | "What is this?" | Pip holds up a stone: "Hva sier denne?" The child says it out loud (unscored, no microphone), and after 2.0 s Pip says it: "/sss/! Som i sol." The scored recall proxy is letter → picture: "Hvilken begynner med denne lyden?" (6.3). | Speaking: no. Proxy: yes. |

No microphone in v1 **[design]**: the RECORD_AUDIO permission, children's voice data under Families policy, and unreliable speech recognition on isolated child phonemes (Q6).

### 4.6 Control of error (self-correcting materials)

Every activity is built so that the material shows the error, not a judge **[design, after Montessori]**:
- A wrong stone in a bridge slot plays **its own** sound, the plank wobbles (0.4 s) and the stone slides back. The child hears that /m/ is not /s/. There is no buzzer, no red X and no "wrong".
- A wrong blend picture: the picked picture plays its name (`lam`), Pip says "Hmm, det var lam. Vi leste sssooolll", and the slide replays.
- Writing from memory: when the child finishes, Pip's model letter fades back in on top of the child's letter in a second colour, so the child compares the two. Nothing is erased in anger and nothing says "wrong".
- Colours never carry right/wrong alone (colour-blind safe): right = the object comes alive (animation + sound).

---

## 5. ZPD in code: the adaptive learning engine

**What this engine is for:** pacing. It keeps items at a level the child can do, decides when a new sound unlocks and when to review. It is **not** a learning claim: in a Norwegian group-randomised trial the adaptive and non-adaptive versions of a computer letter-sound component worked equally well (Solheim et al. 2018, **RCT**). Store text, parent area and any website must not say that the adaptivity makes children learn faster or better.

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
 "strokes":"strokes_s.json","example_word":"w_sol"}
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

BKT (Corbett & Anderson 1995 **[src]**, **theory**: the maths, no child-reading evidence) keeps one number per skill: P(L) = the chance the child knows it.

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
| 3 | 3rd wrong | Pip demonstrates: the horn writes the letter / points at the stone while saying the sound. | demonstration |
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
- **Prior knowledge fast lane (test-out):** before a "meet" lesson, the engine offers 1 item at 4 choices with no hint. If the child gets 3 out of 3 in a row, P(L) = 0.90 and the meet lesson is skipped (watch-then-write is kept, but shortened to 1 pass). A 7-year-old who already knows letters reaches blending in their first session.
- **Session cap (soft end):** at cap − 60 s (11 min with the default 12 min cap; parent setting 10/15/20) no new task starts. The current task finishes, then the read-to-a-grown-up card (10.4), then Pip yawns, gives one offline follow-up (10.1) and the sunset scene plays. Nothing is ever cut mid-task. After the sunset the game does not offer "one more": a new session needs a fresh tap on the sleeping boat, and starts with the warm-up again. There is no lockout or cooldown (the studio bans energy timers). **[design]**, following the Lesekommisjonen "mindre skjerm, mer lek" mandate (**guidance**).

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
const GROWNUP_CARD_BEFORE_END_SEC: float = 60.0   # no new task after cap - 60 s; then the card
# Watch then write (6.1)
const WRITE_LETTER_HEIGHT_FRAC: float = 0.60
const MODEL_STROKE_SEC: float = 0.9          # Pip draws one stroke
const MODEL_HOLD_SEC: float = 1.0            # full model visible
const MODEL_FADE_SEC: float = 1.2            # model fades to empty sand
const WRITE_DONE_IDLE_SEC: float = 1.5       # finger up this long = letter finished
const WRITE_RESAMPLE_POINTS: int = 48
const WRITE_MATCH_MAX: float = 0.18          # mean symmetric point distance, fraction of letter height
const WRITE_MATCH_LOOSEN_STEP: float = 0.02  # +0.02 per hint level used (lenient for 4-year-olds)
const WRITE_MIN_INK_FRAC: float = 0.5        # ink length >= 50% of model arc length
const WRITE_HINT_START_DOT: int = 1          # hint level 1: dotted start point
const WRITE_HINT_REMODEL: int = 2            # hint level 2: Pip models again
const WRITE_HINT_TRACE: int = 3              # hint level 3 (last): full trace overlay
const TRACE_TOLERANCE: float = 0.22          # corridor half-width, only for the hint-3 trace overlay
const TRACE_COVERAGE_DONE: float = 0.90
# Drag and drop
const SNAP_RADIUS_PX: float = 90.0
const MIN_TOUCH_PX: float = 130.0
```

---

## 6. Mini-games (activity templates)

Every activity: 3-6 items, 1-3 minutes, spoken prompt only, no timer, ends on a success. **No speed timers anywhere** (8.3).

### 6.1 Sandskriving (Watch then write), replaces sand tracing in 0.2
Evidence: writing from memory, not tracing, recruited the reading circuit in 5-year-olds (James & Engelhardt 2012, **small trial**; Longcamp et al. 2005, **small trial**). Sandpaper letters are the design inspiration only (Montessori, **theory**).
- **Setting:** wet sand on the beach; Pip writes with his glowing horn.
- **Step 1, watch:** the writing area fills 60% of screen height. Pip writes the letter stroke by stroke from the stroke model (`strokes_s.json`: polylines in a 0-1 box, stroke order, start point per stroke). While each stroke is drawn (0.9 s) the letter's sound plays: continuants sustained for the whole stroke (`ssss`), stops once at the end of the stroke. After the last stroke the full letter stays 1.0 s, Pip says "/s/, som i sol", then the model fades to empty sand over 1.2 s. The child cannot touch the sand during step 1 (touches make Pip say "Se på meg først!").
- **Step 2, write from memory:** empty sand, no dots, no arrows. Pip: "Nå du! Skriv /s/." The child writes with one finger; the sand glows where the finger has been and the sustained sound plays while the finger moves. The letter is finished when the finger has been up for 1.5 s (or the child taps the "Ferdig" shell).
- **Check (lenient, not scored):** resample all the child's ink to 48 points, scale it uniformly into the model's box (centred), and compute the mean symmetric nearest-point distance to the model as a fraction of letter height. Accept if ≤ 0.18 (+0.02 per hint level used) and the ink length ≥ 50% of the model's arc length. Stroke order and direction are **not** checked (4-year-olds).
- **Accepted:** the model fades in on top in a second colour for 0.8 s (compare), then the child's letter lifts out of the sand as a stone and says its sound plus the example word.
- **Not accepted → hint ladder for writing** (the sand is smoothed, 0.4 s, and the child tries again):

| Hint level | What the child gets |
|---|---|
| 0 | Empty sand (default). |
| 1 | A dotted, pulsing start point (130 px) where the first stroke begins. |
| 2 | Pip models the letter again (step 1 repeated), then empty sand with the start point. |
| 3 (last) | Full trace overlay: the dotted letter with stroke arrows; the child traces it (corridor half-width 0.22 of letter height, stroke done at 90% arc coverage). Always ends with the letter lifting out. |

- **Passes per new letter:** 2. Pass 1 = watch + write. Pass 2 = write straight away from memory with no model first (the gap since pass 1 is the point); its hint start is 1 if pass 1 needed hint ≥ 2, else 0.
- **Control of error:** the compare overlay; no reset, no fail, no "feil".
- **Tests:** not scored in BKT (the engine logs the highest hint level used). Feeds period 1.
- **Off screen:** the parent area gives a paper handwriting prompt for each newly met letter (10.3).

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
- **Syllable chunking variant (World 2, two-syllable words, new in 0.2):** for words such as `lese`, `rose`, `nese`, `sola`, `mamma` the slide has a small flat rest stop between the syllables. The rider pauses there; the first chunk plays as one connected unit (`le`), then the second (`se`), then the whole word at normal speed (`lese!`). The word on the slide sign and on every card stays **unbroken**: no hyphen, no gap, no dot between syllables. The only visual cue is a soft arc under each syllable's letters that lights while that chunk plays. Chunking is introduced in World 2, after single-syllable blending is secure in World 1 (Språkløyper: syllables are a later strategy for long words, **guidance**; Häikiö & Luotojärvi 2021: hyphenation gave no benefit, **small trial**). Skill id `blend_2syl`. **[design]**
- **Scored:** picture pick, `blend_*` skill.

### 6.5 Elkonin-skatten (Sound boxes treasure), segmenting, Elkonin boxes
- **Method:** Elkonin sound boxes (Elkonin 1973, a practice tradition, **theory**): push one token per sound.
- **Rule:** "Legg en mynt for hver lyd i `lam`." 3 empty boxes on a treasure chest lid; the child drags a coin into each box; each coin plays the next sound as it lands (/l/ /a/ /m/). In World 1 the boxes match the sound count (no counting error possible, it is modelling). From World 2 there is one extra box; the chest opens only when the coins match the sound count (a wrong count: the lid rattles, Pip says the word slowly again).
- **Scored:** from World 2, `segment_*` skill.

### 6.6 Ordbroa (The word bridge), Montessori moveable alphabet
- **Setting:** a gap in a path over a stream; a word-picture floats on the far side.
- **Rule:** Pip says "`sol`". 3 empty plank slots; 4-6 letter-stones (the right letters plus 1-3 distractors) in a basket. The child drags a stone into a slot; every stone plays its sound when touched. A right stone becomes a plank. A wrong stone plays its sound, wobbles and returns (control of error). When the bridge is complete the child walks across and the word is read aloud while each plank lights up left to right.
- **Montessori point:** encoding (building) a word before reading it.
- **Scored:** per slot, grapheme skill; the whole bridge for `spell_*`.

### 6.7 Lydseiling (Sound sailing), embodied listening, phone tilt
- **Rule:** the boat sails forward slowly and **stops in front of the gates and waits** as long as the child needs (no speed pressure, no timeout). Pip says a sound; 3 buoy-gates show letters. The child tilts the device to steer into the matching gate, or taps the gate (lanes are 33% of the screen width each). Right gate: a dolphin jump and the sound. Wrong gate: the buoy plays its sound and the boat circles back for another pass (no loss).
- **Technical:** `Input.get_accelerometer()` x-axis, dead zone ±0.15 g, full lane at ±0.35 g. The builder must verify on the owner's tablet that the accelerometer reports in the Godot 4.6 Android export (the project setting for sensors may need enabling). Parent toggle "Bevegelseskontroll" (motion controls) on/off.
- **Scored:** yes, grapheme skill (recognition).

### 6.8 Les og gjør (Read and do), comprehension, superhero commands
- **From World 3:** a word or sentence card (`hopp!`, `klapp!`, `snu deg!`). The child reads it (on their own or tapping words to hear them, which counts as hint level 1), then taps one of 3 action pictures. The superhero avatar does the action, and Pip invites the child to do it too ("Gjør det du også!"). The physical part is not scored.
- **World 6:** sentences such as `Mia har en rød båt.` → pick the matching picture of 3 (minimal differences: red/blue boat, boat/bike).
- **Scored:** picture pick, `read_word_*` / `read_sentence_*`.

### 6.9 Kroppsbokstaver and Stavelsestramp (body letters, syllable stomp), embodied rituals
- **Syllable stomp (World 0):** Pip says `en-hjør-ning`; the child taps a big drum once per syllable (scored), and Pip invites stomping along (not scored).
- **Body letters:** after a new letter is written, Pip strikes a pose and the child copies: `i` = arms straight up and head as the dot, `o` = arms in a circle, `l` = stand tall, `s` = a snake wiggle. Sky-writing: "Skriv /s/ i lufta med superfingeren!" and the superhero cape-trail draws it in the sky. 6 s, then a big "Ferdig!" thumb button (or it auto-continues after 8 s). Never scored, because the phone cannot see the child, and pretending it can would teach that the game does not watch them.
- **Movement break** (from 5.3): "Hopp 5 ganger med meg!" Pip counts 1-5 aloud at 0.8 s per jump.
- **Claim limit:** movement is here for engagement and breaks. The evidence for movement is preschool foreign-language vocabulary (Mavilidi et al. 2015, **extrapolated**); we make no claim that body letters or stomping teach letter sounds.
- **Safety:** prompts tell the child to put the device down before jumping ("Legg telefonen ned først!"). Shaking or jumping with the device is never asked for.

### 6.10 Ordbilder (Sight-word lanterns), World 6
- **Rule:** high-frequency irregular words light up as lanterns along the fort wall. "Finn `og`." 3-4 lanterns. Short (5 items), because they are memorised as whole words. Pip explains once: "Dette ordet jukser litt, det sier /ɔ/, ikke /u/." ("This word cheats a bit.")
- **Scored:** `sight_*` skill.

### 6.11 Lydkonserten (The sound concert), breather, free play
- Every learned sound is a shell on a rock. Tapping plays the sound with a musical note; the child can make "music" or let Pip sing a word they tap in sequence. No prompts, no scoring, ends whenever the child taps the boat. This is the breather station every 5th episode.

---

## 7. Pip, the companion (the More Knowledgeable Other)

**Who:** Pip is a small narwhal (the "unicorn of the sea", Arctic, so it fits a Norwegian game) who can float on a bubble over land. His horn glows and draws letters. He is curious and a little clumsy, never a teacher in a suit. Working name; the final name is Q1.

**Role:** Pip is the MKO who models, then does it with the child, then watches, then asks to be taught (gradual release, Pearson & Gallagher 1983, **theory, extrapolated** from a comprehension model).

| Phase | When | Pip's behaviour |
|---|---|---|
| I do | Period 1 of each new sound | Writes the letter in the sand stroke by stroke first (6.1), says the sound slowly, shows the mouth (a close-up of his mouth shape for /m/ (lips closed), /a/ (wide open)). |
| We do | First 3-5 items of a new skill | Hint start level 2. Pip slides down Lydsklia with the child and says the sounds along. |
| You do | P(L) ≥ 0.6 | Pip sits to the side and only reacts. Hints only on idle or error (ladder from level 0). |
| You teach | From World 5, 1 item per session; World 6 throughout | Pip "forgets": "Hmm, hva sa den nå igjen?" The child taps the right stone to teach Pip (scored like Hør og finn). In World 6 the child reads to Kaptein Hysj (protégé effect). |

Pip's language rules **[design]**:
- Every line ≤ 8 words for prompts, ≤ 12 for story. One instruction per line.
- **Praise is informational, not inflated:** "Du hørte /s/ i sol!" (what the child did), not "Fantastisk! Du er så flink!" Basis: positive informational feedback raised intrinsic motivation (Deci, Koestner & Ryan 1999, **meta-analysis**). Mueller & Dweck 1998 (process vs person praise) is **not** used as support: a close replication failed (Li & Bates 2019, n = 624). Max 1 praise line per 3 correct answers; the other right answers get the world reaction only.
- **After an error Pip never says "feil".** He reacts to the material ("Den sa /m/. Vi leter etter /s/").
- Pip has a small set of physical reactions (giggle, spin, yawn, "hmm" head tilt) so most feedback needs no words.

---

## 8. Motivation without extrinsic-reward traps

### 8.1 Devil's advocate: where common gamification fights Montessori (and the learning)

| Mechanic | Why studios use it | Why it hurts here |
|---|---|---|
| **Stars per level (1-3)** | Clear goal, replay value | Turns learning into a performance grade. A child who gets 1 star sees "I'm bad at this". Children replay for stars on levels they already know, which is the opposite of the ZPD. Montessori: no external grading, the work carries its own feedback. |
| **Coins, gems, loot, random chests** | A reward loop | Expected tangible rewards lower later free interest in the activity (Lepper et al. 1973 with preschoolers, **small trial**; Deci et al. 1999, **meta-analysis**: tangible rewards are worse for children). Random rewards are variable-ratio schedules (the slot-machine pattern). Coins make reading the tax you pay to get loot. |
| **Daily streaks, login rewards** | Retention | Loss aversion and guilt; a 5-year-old cannot control when they get the phone. The parent ends up nagging. A dark pattern for kids. |
| **Timers, speed bonuses** | Excitement | Punish slow processing, which is normal at 4-5. They add anxiety and reward guessing over decoding. Lesesenteret: accuracy before speed; speed apps only briefly and with care (Språkløyper, **guidance**). Banned (8.3). |
| **Lives / energy / fail screens** | Stakes | There is no "fail" in learning to read; a fail screen teaches avoidance. Energy timers are banned by the studio rules anyway. |
| **Leaderboards, comparisons** | Social pressure | Comparison with others at 4-7 is harmful; children develop at very different paces. |
| **Pop-up celebrations (confetti on every tap)** | Juice | They pull attention off the task (Hirsh-Pasek et al. 2015 "engaged, not distracted", **theory**), and praise inflation makes real feedback meaningless. |

**Devil's advocate against my own choice:**
- Montessori would say a screen is already too abstract: glass has no texture, and the sandpaper letter's value is touch. *Answer:* agreed, so the app hands writing back to paper: the child writes letters from memory in the sand (6.1), the parent area gives a paper handwriting prompt (10.3), and every session ends with an offline follow-up (10.1). The Montessori materials are design inspiration, not evidence: the meta-analysis supports Montessori education overall (Randolph et al. 2023, g = 0.24, **meta-analysis**), not single materials on a screen.
- Montessori's freedom of choice vs an engine that chooses. *Answer:* "freedom within limits" means the engine prepares the environment (2-3 lit stations, all in the ZPD) and the child chooses among them, plus free play in Lydkonserten.
- Many 4-year-olds love stickers and stars, and some structure helps. *Answer:* the child gets visible, collectable progress, but the collectable is **the learning itself** (8.2), not a currency.
- World restoration is still a contingent reward. *Answer:* yes, but it is an endogenous consequence (the reading **makes** the sun rise: intrinsic integration, Habgood & Ainsworth 2011, **extrapolated** from maths at ages 7-11). It is never spendable, never random and never lost.

### 8.2 What we use instead

1. **World restoration (the main progress signal):** each island starts grey and silent (a desaturation shader parameter, 0 = grey, 1 = full colour; ambient sound is wind only).
   - Finishing a station for the first time restores **its zone** (colour fades in over 2.5 s, plants grow, an animal returns). This is tied to effort and completion, so slow learners see progress too.
   - **Mastering a sound** adds a **music stem** to the island theme (6 sounds = 6 instruments, so the island literally sings the sounds the child knows) and makes the zone "bloom" (flowers, baby animals).
   - Nothing ever decays. An island the child stopped visiting stays as beautiful as they left it.
2. **Lydboka (The sound book):** an album with one page per learned sound. Each page shows the letter, plays the sound and the child's example words, and shows a little picture drawn from the island where they learned it. Mastered pages get a gold edge. This is the child's alphabet; they can browse it any time from the boat. It is the Montessori "work made visible".
3. **Autonomy:** choose the station order, choose the avatar look (superhero cape / pirate hat / unicorn rider; 3 options in the MVP, all free from the start), decorate a corner of the island with the restored animals.
4. **Competence made visible:** Pip's informational praise; the child reading a word out of the world itself (a sign on the restored bridge says `sol`).
5. **Relatedness:** Pip and the island characters remember the child ("Du lærte meg /l/!"); the daily read-to-a-grown-up step (10.4) puts a real person at the end of every session.

### 8.3 Hard rules (new in 0.2)

1. **No speed timers anywhere.** No countdowns, no time-limited answers, no speed bonuses, no moving targets that leave if the child is slow (Lydseiling waits, 6.7). Latency is logged for the engine but never shown, never scored and never used to reduce a reward. (Språkløyper, **guidance**.)
2. **Session cap:** soft end at about 12 min (parent setting 10/15/20), never cut mid-task (5.6). No "one more level" prompt after the sunset.
3. **One offline follow-up per session:** Pip ends every session with one thing to do away from the screen (10.1). (Lesekommisjonen mandate "mindre skjerm, mer lek", **guidance**.)
4. **No claim that the adaptivity, the movement or the Montessori materials cause learning** in any store text, parent text or website (sections 5, 6.9, 4.1).

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

Total: about 45 skill groups (incl. the cluster and multi-letter skills in 4.3.1), about 90 episodes (Worlds 3 and 5 each +4 over 0.1) ≈ 30-35 sessions of 12 min at a typical pace (my estimate, it depends entirely on the child). Norwegian is planned slower than Finnish practice on purpose (4.3.1).

---

## 10. Session, onboarding, parent area, privacy

### 10.1 Session shape

| Time | What happens |
|---|---|
| 0:00-0:20 | Boat in the bay. Pip pops up: "Hei, kaptein! Der er du!" Recap of the last sound learned: Pip plays it and the child taps the matching shell (an easy warm-up item). |
| 0:20-0:40 | Tap the island; the boat sails (8 s of sailing with the island theme playing, which is the music the child restored). |
| 0:40-11:00 | 3 episodes of about 3.3 min each: pick one of 2-3 lit stations → 3-6 items → zone restored. |
| ~11:00 | No new task starts. The current task finishes. |
| ~11:00-12:00 | **Read to a grown-up** (10.4): the child reads today's words to an adult; the adult holds the "Hørt!" button (or the child taps "Ingen voksen nå"). |
| ~12:00 | Pip yawns ("Jeg blir så søvnig…"). |
| End | Sunset sail back; Pip says what they learned today ("I dag lærte du /m/, som i mus!") and gives **one offline follow-up** (below); Lydboka opens on today's page; the screen fades to the sleeping boat. The game quits to the home screen on the next tap or stays on the calm boat screen. |

**Offline follow-up (every session, new in 0.2) [design]:** one spoken suggestion from `content/nb_reading/offline.json`, 3 per sound plus 3 general ones, linked to the sound learned or practised most today. Examples: "Finn tre ting hjemme som begynner med /m/!", "Skriv /s/ med fingeren på dugg i vinduet!", "Klapp navnet ditt i stavelser!". The same line appears in the parent area under "I dag". No check, no follow-up question next session. Basis: Lesekommisjonen mandate "mindre skjerm, mer lek" (**guidance**).

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
  - **Parent script** (10.4), shown on the first parent-area visit and always one tap away.
  - **Paper handwriting prompt:** one card per newly met letter. It shows the lowercase letter with stroke order (start dot, numbered arrows) for the adult and these steps: "1. Skriv bokstaven på papir mens du sier lyden (/s/, ikke 'ess'). 2. Dekk den til. 3. Barnet skriver den fra hukommelsen. 4. Se på begge sammen." (Write it while saying the sound; cover it; the child writes it from memory; compare.) Basis: writing from memory, not tracing (James & Engelhardt 2012, **small trial**).
  - **I dag:** today's offline follow-up (10.1) and the words read to a grown-up.
  - Settings: session length 10/15/20 min; motion controls on/off; sound volume and Pip voice volume; written text Auto / On / Off (10.5); language (when packs exist).
  - "Read together" tips: 3 more offline activities per world (draw letters in sand, sound-hunt at dinner: "find something that starts with /m/").
  - Reset progress (confirm twice).
  - Privacy statement in plain words: "Alt lagres bare på denne enheten. Ingenting sendes noe sted." (Everything stays on this device. Nothing is sent anywhere.)
- No purchases, no external links, no rating prompts, anywhere in the app (also not behind the gate).

### 10.4 Read to a grown-up (daily, core) and the parent script [design]

**Why it is core:** the GraphoGame meta-analysis found no overall effect on word reading (McTigue, Solheim, Zimmer & Uppstad 2020, 19 studies, g = -0.02, **meta-analysis**); in studies with high adult interaction the effect was g = 0.48. An English trial with 398 pupils found no effect (EEF/NFER, **RCT**) and a French trial with N = 921 found small effects of 0.18-0.27 (Lassault et al. 2022, **RCT**). **Expected effect of this app: small.** The adult step is the design's best bet for a real effect, not a proven one. No store or parent text may promise more.

**The step (every session, at the session cap, 5.6):**
1. Pip: "Les ordene for en voksen!" ("Read the words to a grown-up!")
2. A big card shows 3-5 words the child built or read **this session** (Ordbroa and Lydsklia items answered correctly, first-attempt-correct ones first; if fewer than 3, top up with mastered words). Words are large, lowercase and never hyphenated. In World 0 (no letters yet) the card shows 3 pictures and the child claps their syllables for the adult.
3. The child reads each word aloud. Tapping a word plays it (allowed, it is a help, not a fail). No microphone, no scoring.
4. **Adult button:** bottom right, text-labelled "Voksen: Hørt!", press and hold 1.5 s (a ring fills). A 4-5 year old cannot read the label; an older child pressing it costs nothing. On release: Pip: "Takk for at du hørte på!", a soft fanfare (1.2 s), and the words go into the Lydboka page "Lest for en voksen" with the date.
5. **No adult present:** a big picture button (a sleeping sun) "Ingen voksen nå". Pip: "Da leser vi dem for en voksen neste gang!" The words carry over to the next card. No penalty, no streak, no count of missed days anywhere.
6. Then the yawn, the offline follow-up and the sunset (10.1).

**Parent script** (parent area, Norwegian with the English meaning; 5 lines, readable in 20 s):
1. "Sitt sammen med barnet de siste minuttene." (Sit with your child for the last minutes.)
2. "La barnet lese selv. Vent, ikke si ordet først." (Let the child read. Wait, do not say the word first.)
3. "Står barnet fast: si den første lyden, ikke bokstavnavnet (/s/, ikke 'ess')." (If stuck: say the first sound, not the letter name.)
4. "Si hva barnet gjorde: 'Du trakk sammen s-o-l til sol!'" (Say what the child did.)
5. "Gjør dagens forslag uten skjerm sammen." (Do today's off-screen idea together.)

Below the script, one plain sentence on expected effects: "Samlet viser studier liten eller ingen effekt av slike spill, og større effekt når en voksen er tett med." (Overall, studies show little or no effect from games like this, and a larger effect when an adult is closely involved.)

### 10.5 When written instructions appear

Audio stays the main channel throughout. Text is added gradually, and only text the child can read **[design]**:
- Worlds 0-2: no instruction text at all.
- From World 3, or when 15 or more graphemes are mastered (setting `Auto`): Pip's spoken line also appears as a subtitle, karaoke-highlighted word by word in sync with the voice. Words made only of graphemes the child has mastered are shown in **full contrast and tappable** (tap = hear the word); other words are shown in lighter grey. As the child learns, more of each line turns readable, so they see their own progress in every sentence.
- World 6: for 1 line per episode, Pip asks the child to read the instruction first before he says it (a scored `read_sentence` item).
- Production need: word-level timestamps for every voiced line (forced alignment; the tool is the builder's choice, Q7).

### 10.6 Privacy and store compliance

- **No network:** the APK has no INTERNET permission and no analytics, crash reporter, ads SDK or account. All learner data is `user://learner.json` + `user://evidence.log` on the device. Data safety form: "no data collected, no data shared".
- **Google Play Families policy** (checked 2026-10-03 **[src]**): child-directed apps must not transmit device identifiers (ad ID, IMEI and so on), must not request location, and may only use approved SDKs. With no SDKs and no network we meet all of it by design.
- **GDPR for children:** no personal data is processed off the device, so no consent flow is needed. Norway's age of digital consent is 13 (Personopplysningsloven § 5, not re-checked, verify before public use); this is not triggered.
- **Permissions:** none, except possibly VIBRATE for haptics (an install-time "normal" permission with no data; Q8). No RECORD_AUDIO, CAMERA or location.
- **Child's name:** never asked for. Pip says "kaptein".

---

## 11. Feel (feedback for every action)

| Action | Sound | Visual | Duration | Haptic (if Q8 yes) |
|---|---|---|---|---|
| Tap any letter-object | its phoneme (short) | scale 1.0 → 1.12 → 1.0, ease-out-back | 0.25 s | 15 ms |
| Hold a letter | sustained phoneme (loop) | soft glow ring | while held | none |
| Pip models a letter | sustained phoneme per stroke (stops: once at stroke end) | horn draws the stroke, glow trail | 0.9 s per stroke + 1.0 s hold + 1.2 s fade | none |
| Child writes in the sand | sustained phoneme + sand hiss while the finger moves | sand glow trail, 8 sparkle particles/s | while moving | none |
| Letter accepted | phoneme + example word | model fades in on top in a second colour (0.8 s), then the letter rises out of the sand as a stone, spin 360° | 2.0 s | 40 ms |
| Letter not accepted | Pip "hmm" (no buzzer) | sand smooths over | 0.4 s | none |
| Read-to-a-grown-up "Hørt!" hold | soft fanfare + Pip "Takk for at du hørte på!" | ring fills during the 1.5 s hold, words fly into Lydboka | 1.5 s hold + 1.2 s | 50 ms |
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
| 2 | First sound pair a + s (period 1) | Sandskriving a, s (watch then write); body letters | 3 min | not scored |
| 3 | a/s recognition and recall | Hør og finn, Første lyd (`sol`, `ape`) | 3.5 min | 20-30% |
| 4 | Blending idea: `sa` (2 sounds) | Lydsklia, Elkonin (modelled) | 3.5 min | 15-30% |
| 5 | **Breather** | Lydkonserten, restore the beach | 2 min | none |
| 6 | i | Sandskriving, Hør og finn (3 choices) | 3.5 min | 15-30% |
| 7 | Building words: `is`, `si` | Ordbroa (2 slots), Lydsklia | 3.5 min | 15-30% |
| 8 | l + first CVC: `sil`, `sal`, `lim` | Sandskriving, Lydsklia, Lydseiling | 4 min | 15-30% |
| 9 | o (/u/): `sol`, `lo`, `los`, `silo` | Sandskriving, Lydsklia (the sun rises) | 4 min | 15-30% |
| 10 | **Breather** | Lydkonserten, decorate the meadow, Lydboka | 2 min | none |
| 11 | m: `lam`, `mil`, `mos`, `slim` | Sandskriving, Ordbroa (3 slots), Første lyd | 4 min | 15-30% |
| 12 | Longer words: `lama`, `sola`, `salami` (connected blending only; syllable chunking comes in World 2) | Lydsklia (4-6 stones), Ordbroa | 4 min | 20-30% |
| 13 | **Island gate** (Hysj's locked gate shows `sol`, `is`, `lam`) | Les og velg (3 words) | 3 min | 15-25% |
| 14+ | Review loop until all 6 sounds are mastered (5.6) | child picks from 3 lit stations | 3.5 min each | 15-30% |

Every session, whatever the episode, ends with the read-to-a-grown-up card (10.4) and an offline follow-up (10.1).

MVP decodable word list (o = /u/ only, no names, no doubles): `is, sa, si, la, li, lo, sal, sil, lim, mil, mos, los, lam, sol, slim, sola, silo, lama, salami`. Picture words for Første lyd, 4 per sound (first sound must be the taught value): a: `ape, and, ananas, appelsin`; s: `sol, sel, sau, sild`; i: `is, igle, iglo` (only 3 safe); l: `lam, løve, lampe, lue`; o (/u/): `ost, oter` (only 2 safe, see Q3); m: `mus, melk, måne, mamma`. **[design, needs a native-teacher check]**

---

## 13. MVP scope (first playable slice)

**In:**
- Hub ship + World 0 lite (2 activities) + World 1 Enhjørningenga (one island, 6 sounds a s i l o m, 13 episodes + review loop).
- Activities: Sandskriving (watch then write), Hør og finn, Første lyd, Lydsklia, Ordbroa, Lydkonserten, body-letter ritual, movement break. (Lydseiling and Elkonin are optional stretch goals.)
- `learn_core/` engine complete (BKT, selector, hint ladder, planner, local save) with headless unit tests that replay scripted answer sequences and check P(L), hint starts and step-down, mirroring the simulation numbers in 5.2.
- Pip with 4 animations (idle, talk, giggle-spin, yawn) + horn-writing (stroke-by-stroke model).
- 3 avatar looks, island restoration (desaturation shader + 6 music stems), Lydboka (6 pages).
- Read-to-a-grown-up card every session (10.4) + offline follow-ups for the 6 sounds (`offline.json`, 21 lines).
- Parent gate + parent area (parent script, paper handwriting prompts for a s i l o m, "I dag", progress, session length, motion, reset, privacy text).
- Norwegian bokmål audio only; landscape; no network.

**Audio production for the MVP (the hard dependency):**

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

**Voice (Q2 partly resolved):**
- **Placeholder voice: Microsoft Finn (nb-NO) via edge-tts**, generated as audio files **at build time** by a script in the repo. The app itself never calls a TTS service and keeps no INTERNET permission; only the build step needs a network.
- **Isolated sounds are cut from carrier words/sentences**, because TTS adds vowels to bare phonemes and clips stops. For each phoneme generate 2-3 carriers with the sound next to a vowel or at a word edge (for /s/: `is`, `sol`; for /m/: `lam`, `mus`), cut at zero crossings with 10 ms fades. Continuants: the sustained 2.0 s clip loops a steady 150-250 ms middle section. Stops: keep the burst, no following vowel ("t", not "tə").
- **Final voice:** the owner picks it from a listening page that plays the same lines (instructions, praise, words, blends, isolated sounds) in each candidate voice. Until then every file is listed in `content/nb_reading/audio_manifest.json` with `voice` and `status: "placeholder" | "final"`; game-qa blocks a store release while any entry is `placeholder`.
- Output spec **[design]**: 48 kHz mono, -18 LUFS integrated, peaks ≤ -1 dBFS, Ogg Vorbis q5. One voice for Pip, a different one for Hysj. If the final voice is a human recording: a quiet room and the same mic distance throughout.

**Deferred:** Worlds 2-6; English content pack (it needs its own phonics order, SATPIN-style, and a separate design); maths pack; uppercase; Lydseiling tilt (if not done); Elkonin scoring; Les og gjør; sight words; karaoke text; microphone / speech features; multiple child profiles; haptics (if Q8 is no); Play Store release (studio Play Store checklist).

**MVP "done" test for game-qa:** a 4-year-old (the test child, if available) plays 3 sessions without an adult having to read any instruction to them, an adult does the read-to-a-grown-up step at least once, and the parent area shows at least 3 sounds as "øver" or "sikker". A grep of all store and parent text finds no claim that adaptivity, movement or Montessori materials cause learning (8.3). The headless engine tests pass. 60 fps on the PerfOverlay on the owner's tablet (calm game: 30 fps allowed per DESIGN.md if needed).

---

## 14. Open questions for the owner

1. **Companion:** is a narwhal called Pip right, or do you want a unicorn foal, a parrot (pirate theme, and parrots repeat sounds) or another animal? Do you want a name?
2. **Voice (partly resolved):** placeholder = Microsoft Finn via edge-tts, built as files, isolated sounds cut from carriers (13). Still open: which voice you pick on the listening page for Pip and which for Hysj, and whether the final is TTS or a human recording.
3. **Teacher review:** can a Norwegian 1st-grade teacher or special-ed teacher check the sound order (4.3), the o = /u/ choice for World 1, and the picture-word list in 12 (especially safe o-words: I only trust `ost` and `oter`)?
4. **English:** does "English selectable" mean (a) Pip speaks English while still teaching Norwegian letters (for non-Norwegian parents and children in Norway), or (b) a full English reading course (a separate content pack and design, deferred)? I assumed (b) later and only Norwegian in v1.
5. **Orientation: resolved.** Landscape accepted (3.1).
6. **Microphone:** no speech recognition in v1 (permission, children's voice data, poor accuracy on child phonemes). Confirm, or do you want it researched as a later option?
7. **Karaoke text timing:** OK to defer word-timed subtitles to World 3 (post-MVP)?
8. **Haptics:** OK to add the VIBRATE permission (install-time, no data, no prompt), or keep the app at zero permissions?
9. **Profiles:** one child per device in v1, or do siblings need 2-3 profiles from the start?
10. **Language: resolved.** Bokmål only.
11. **Store:** is this a sideload/family app first, or aimed at Google Play (Families program, Teacher Approved) from the start?
12. **Grown-up step wording:** is "Voksen: Hørt!" (hold 1.5 s) the right adult button, and should the parent script be shown before the very first session or only in the parent area?
13. **Teacher acceptance:** RESEARCH.md notes teachers will accept a screen app only if it is short, play-based and points children to offline reading. Do you want a Norwegian teacher to read 10.1-10.4 before the builder starts on the parent area?

---

## Sources

Full evidence review, verification status of every citation and what was not checked: `docs/RESEARCH.md` (2026-10-03). Corrected citations used in this doc:

**Phonics, blending, writing**
- National Reading Panel 2000, *Report of the National Reading Panel*, NICHD, NIH Pub. No. 00-4769.
- Ehri, Nunes, Stahl & Willows 2001, *Review of Educational Research* 71(3):393-447, doi:10.3102/00346543071003393.
- Ehri, Nunes, Willows et al. 2001, *Reading Research Quarterly* 36(3):250-287, doi:10.1598/RRQ.36.3.2.
- Ehri 1995, *Journal of Research in Reading* 18(2):116-125; Ehri 2005, *Scientific Studies of Reading* 9(2):167-188.
- Share 1995, *Cognition* 55(2):151-218.
- Gonzalez-Frey & Ehri 2021, *Scientific Studies of Reading* 25(3):272-285, doi:10.1080/10888438.2020.1776290.
- Seymour, Aro & Erskine 2003, *British Journal of Psychology* 94(2):143-174.
- Häikiö & Luotojärvi 2021, *Scientific Studies of Reading*, doi:10.1080/10888438.2021.1874384.
- Lyytinen, Richardson & Aro 2019, Cambridge University Press chapter, doi:10.1017/9781108553377.006.
- Longcamp, Zerbato-Poudou & Velay 2005, *Acta Psychologica* 119:67-79.
- James & Engelhardt 2012, *Trends in Neuroscience and Education* 1(1):32-42, doi:10.1016/j.tine.2012.08.001.
- Elkonin 1973, "U.S.S.R.", in Downing (Ed.), *Comparative Reading*, pp. 551-579.

**Apps, adults, adaptivity**
- McTigue, Solheim, Zimmer & Uppstad 2020, *Reading Research Quarterly* 55(1):45-73, doi:10.1002/rrq.256.
- EEF/NFER GraphoGame trial, England, 398 pupils.
- Lassault et al. 2022, *Scientific Studies of Reading* 26(6):449-468.
- Solheim et al. 2018, *Learning and Instruction*, doi:10.1016/j.learninstruc.2018.05.004; Solheim et al. 2024, *Journal of Research on Educational Effectiveness*, doi:10.1080/19345747.2024.2333734.
- Corbett & Anderson 1995, *User Modeling and User-Adapted Interaction* 4(4):253-278, doi:10.1007/BF01099821.
- Wilson, Shenhav, Straccia & Cohen 2019, *Nature Communications* (the 85% rule).

**Motivation, play, Montessori**
- Lepper, Greene & Nisbett 1973, *JPSP* 28(1):129-137, doi:10.1037/h0035519.
- Deci, Koestner & Ryan 1999, *Psychological Bulletin* 125(6):627-668, doi:10.1037/0033-2909.125.6.627.
- Mueller & Dweck 1998, *JPSP* 75(1):33-52, not used as support: failed replication by Li & Bates 2019, *JEP: General* 148(9):1640-1655.
- Hirsh-Pasek et al. 2015, *Psychological Science in the Public Interest* 16(1):3-34.
- Habgood & Ainsworth 2011, *Journal of the Learning Sciences*, doi:10.1080/10508406.2010.508029.
- Mavilidi et al. 2015, *Educational Psychology Review* 27(3):413-426.
- Randolph et al. 2023, *Campbell Systematic Reviews*, doi:10.1002/cl2.1330; Lillard & Else-Quest 2006, *Science* 313:1893-1894.
- Wood, Bruner & Ross 1976, *Journal of Child Psychology and Psychiatry* 17(2):89-100; Pearson & Gallagher 1983, *Contemporary Educational Psychology* 8(3):317-344.
- Unverified (cited as theory only): Wood & Middleton 1975; Wood, Wood & Middleton 1978; Montessori 1912; Vygotsky 1978; Chase et al. 2009.

**Norwegian guidance and policy**
- Lesesenteret, Språkløyper, "Når elever strever med å lese ord".
- Udir, læreplan i norsk (NOR01-06; NOR01-07 not read).
- Lesekommisjonen, mandate ("mindre skjerm, mer lek").
- Kristiansund kommune, "Lese- og skriveopplæring 1. trinn".

**Store and privacy**
- Google Play Families policy (checked 2026-10-03).
- Personopplysningsloven § 5 (age of digital consent 13), not re-checked; verify before public use.
