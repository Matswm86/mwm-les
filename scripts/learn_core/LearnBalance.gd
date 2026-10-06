class_name LearnBalance
extends RefCounted
## Every learning and activity balance number (GDD 0.2, 5.7, plus slice
## additions marked below). Nothing here knows what
## a letter is; the reading content lives in content/nb_reading/.

# BKT
const P_INIT: float = 0.10
const P_TRANSIT: float = 0.12
const P_SLIP: float = 0.10
# weight of a CORRECT answer per hint level
const HINT_EVIDENCE: Array[float] = [1.0, 0.7, 0.3, 0.0, 0.0]
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
const FRAGILE_BELOW_P: float = 0.60  # slice: "new/fragile" bucket edge (GDD 5.3)
# Format knobs (slice addition): near distractors make a slip more likely.
const NEAR_SLIP_EXTRA: float = 0.05
const MAX_CHOICES: int = 4
# Hints and idle
const IDLE_HINT_SEC: float = 6.0
const IDLE_HINT_MAX_LEVEL: int = 2  # slice: idle alone climbs to level 2 (GDD 5.4)
const HINT_MAX: int = 4
const HINT_START_NEW_SKILL: int = 2
const HINT_START_MAX: int = 2  # slice: faded start cap (GDD 5.4 "max 2")
const IDLE_WAVE_SEC: float = 30.0
const IDLE_PAUSE_SEC: float = 90.0
const RANDOM_TAP_COUNT: int = 4
const RANDOM_TAP_WINDOW_SEC: float = 1.5
const RECALL_WAIT_SEC: float = 2.0
# Session
const SESSION_SOFT_END_SEC: float = 720.0
const SESSION_CAP_OPTIONS_SEC: Array[float] = [600.0, 900.0, 1200.0]
const GROWNUP_CARD_BEFORE_END_SEC: float = 60.0  # no new task after cap - 60 s; then the card
const GROWNUP_HOLD_SEC: float = 1.5  # adult holds "Hørt!"
const GROWNUP_CARD_WORDS_MIN: int = 3
const GROWNUP_CARD_WORDS_MAX: int = 5
# Watch then write (GDD 0.2, 6.1)
const WRITE_LETTER_HEIGHT_FRAC: float = 0.60
const MODEL_SPEED: float = 0.75  # Pip's pen, letter heights per second (calm)
const MODEL_STROKE_MIN_SEC: float = 0.6  # shortest stroke (the dot on i)
const MODEL_HOLD_SEC: float = 1.0  # full model visible
const MODEL_FADE_SEC: float = 1.2  # model fades to empty sand
const WRITE_DONE_IDLE_SEC: float = 1.5  # finger up this long = letter finished
const WRITE_RESAMPLE_POINTS: int = 48
# Lenient check (owner report 2026-10-03): position, size, stroke order,
# direction and stroke count are ignored. Accept when the ink is closer to the
# target letter than to every other known letter AND under a loose limit.
const WRITE_MATCH_MAX: float = 0.095  # mean symmetric point distance, fraction of letter size
const WRITE_MATCH_LOOSEN_STEP: float = 0.02  # +0.02 per hint level used
const WRITE_TAIL_PCT: float = 0.95  # distance blends the mean with this percentile
const WRITE_TAIL_WEIGHT: float = 0.5
const WRITE_ROTATIONS_DEG: Array[float] = [-12.0, -6.0, 0.0, 6.0, 12.0]  # slant is not an error
const WRITE_DOT_MAX_FRAC: float = 0.22  # a stroke this small (of the letter size) up top is a dot
const WRITE_DOT_MISMATCH: float = 0.05  # dot present/missing vs the model
const WRITE_STEM_MISMATCH: float = 0.05  # right-side stem (a) present/missing vs the model
const WRITE_STEM_CORNER_FRAC: float = 0.11  # ink this close to the box's bottom-right corner = a stem
const WRITE_STEM_MIN_WIDTH_FRAC: float = 0.5  # narrower ink has no bowl to check
const WRITE_STEM_MODEL_ASPECT: float = 0.8  # only round models (a, o, m) get the stem check
const WRITE_TIE_MARGIN: float = 0.003  # a near-tie with another letter goes to the target
const WRITE_MIN_INK_FRAC: float = 0.4  # ink length >= 40% of model arc length (after size fit)
const WRITE_MAX_INK_FRAC: float = 2.5  # more ink is a scribble (a letter gone over twice is ~2)
const WRITE_MIN_SIZE_PX: float = 40.0  # smaller ink is a tap, not a letter
const WRITE_NEAR_MAX: float = 0.30  # third try: accepted if anywhere near
const WRITE_NEAR_ATTEMPT: int = 3  # the try that only has to be near
const WRITE_ANY_INK_ATTEMPT: int = 4  # from this try any letter-sized ink lifts (no endless loop)
# Orientation check (GDD 6.1): letters whose mirror image is wrong
const ORIENT_CHECK_LETTERS: Array[String] = ["s", "b", "d", "p", "q", "j", "z"]
const ORIENT_DIST_MARGIN: float = 0.015
const ORIENT_ANGLE_MARGIN_DEG: float = 12.0
const ORIENT_TANGENT_SPAN: int = 2
const WRITE_HINT_START_DOT: int = 1  # hint level 1: dotted start point
const WRITE_HINT_REMODEL: int = 2  # hint level 2: Pip models again
const WRITE_HINT_TRACE: int = 3  # hint level 3 (last): full trace overlay
const WRITE_COMPARE_SEC: float = 0.8  # accepted: model shown over the child's letter
const WRITE_SMOOTH_SEC: float = 0.4  # not accepted: sand smooths
const TRACE_TOLERANCE: float = 0.22  # corridor half-width, only for the hint-3 trace overlay
const TRACE_COVERAGE_DONE: float = 0.90
# Activity extras (GDD 6.0)
const GHOST_DEMO_FIRST_USE: bool = true
# Drag and drop
const SNAP_RADIUS_PX: float = 90.0
const MIN_TOUCH_PX: float = 130.0
