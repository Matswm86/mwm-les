class_name GameTune
extends RefCounted
## Presentation and layout numbers for the game (palette from DESIGN.md 2,
## camera from 7.5, layout, tweens). Learning numbers live in LearnBalance.

# --- Palette: UI chrome
const UI_BG: Color = Color(1.00, 0.96, 0.90)
const UI_PANEL: Color = Color(1.00, 1.00, 1.00)
const INK: Color = Color(0.11, 0.17, 0.27)
const GO: Color = Color(0.12, 0.50, 0.23)
const SEA_BTN: Color = Color(0.11, 0.39, 0.72)
const GOLD: Color = Color(1.00, 0.76, 0.10)
const CORAL: Color = Color(0.79, 0.27, 0.12)
# --- Palette: world
const SKY_TOP: Color = Color(0.36, 0.71, 0.94)
const SKY_HORIZON: Color = Color(0.85, 0.95, 1.00)
const SEA_DEEP: Color = Color(0.12, 0.44, 0.85)
const SEA_SHALLOW: Color = Color(0.25, 0.72, 0.91)
const FOAM: Color = Color(0.96, 0.98, 1.00)
const SAND: Color = Color(0.96, 0.84, 0.55)
const SAND_WET: Color = Color(0.80, 0.64, 0.40)
const GRASS: Color = Color(0.42, 0.76, 0.29)
const GRASS_SHADE: Color = Color(0.24, 0.56, 0.23)
const ROCK: Color = Color(0.55, 0.48, 0.42)
const HERO_RED: Color = Color(0.91, 0.25, 0.17)
const UNICORN_PINK: Color = Color(1.00, 0.56, 0.75)
const SHADOW_TINT: Color = Color(0.16, 0.21, 0.31)
const WOOD: Color = Color(0.62, 0.40, 0.22)
const WOOD_LIGHT: Color = Color(0.80, 0.58, 0.34)
const LEAF: Color = Color(0.36, 0.72, 0.30)
const LEAF_DARK: Color = Color(0.27, 0.62, 0.27)
const PIP_BACK: Color = Color(0.52, 0.74, 0.96)
const PIP_BELLY: Color = Color(0.99, 0.96, 0.88)
const PIP_SPOT: Color = Color(0.36, 0.55, 0.86)
const PIP_CHEEK: Color = Color(1.00, 0.62, 0.70)
const PIP_HORN: Color = Color(1.00, 0.90, 0.60)
const EYE: Color = Color(0.08, 0.10, 0.16)
const FLOWER_COLORS: Array[Color] = [
	Color(1.00, 0.56, 0.75),
	Color(1.00, 0.90, 0.30),
	Color(1.00, 1.00, 1.00),
	Color(0.95, 0.42, 0.30),
	Color(0.62, 0.78, 1.00),
]
# --- Lighting
const SUN_ENERGY: float = 0.85
const AMBIENT_ENERGY: float = 0.32
const SUN_PITCH_DEG: float = -52.0
const SUN_YAW_DEG: float = -35.0
const SHADOW_MAX_DISTANCE: float = 60.0
# --- Island layout (world metres; angle 0 = +x, 90 = +z toward the camera)
const ISLAND_RADIUS: float = 12.5
const ISLET_CENTER: Vector3 = Vector3(23.4, 0.0, 1.0)  # far enough for a 7 m word bridge
const ISLET_RADIUS: float = 3.4
const ZONE_RADIUS: float = 9.0
const ZONE_A_ANGLE: float = 118.0  # Hør og finn, south-west beach
const ZONE_B_ANGLE: float = 66.0  # Sandskriving, south beach
const ZONE_C_ANGLE: float = 8.0  # Ordbroa, east shore facing the islet
const UNICORN_ANGLE: float = 88.0  # the unicorn (a silent animal), inland behind the writing beach
const UNICORN_INSET: float = 0.52
const STATION_INSET: float = 0.86  # fraction of the coast radius where a station stands
const LETTER_SPACING: float = 2.6
# --- Camera (DESIGN 7.5)
const CAM_FOV: float = 50.0
const CAM_PITCH_DEG: float = 38.0
const CAM_HUB_TARGET: Vector3 = Vector3(3.5, 0.0, 0.5)
const CAM_HUB_DISTANCE: float = 33.0
const CAM_HUB_PITCH_DEG: float = 20.0  # story shot: lower than 38 so sky and clouds show
const CAM_STATION_DISTANCE: float = 7.6
const CAM_WRITE_PITCH_DEG: float = 64.0
const CAM_WRITE_DISTANCE: float = 7.5
const CAM_PILE_DISTANCE: float = 8.0  # Sandskriving payoff: the stones by the bridge
const WRITE_STONE_SCALE: float = 1.9  # the letter stone that lifts out of the sand
const WRITE_STONE_ROLL_M: float = 9.0  # how far it rolls toward the bridge (out of view)
const PILE_STONE_SCALE: float = 1.0
const CAM_FLY_SEC: float = 1.8
const CAM_INTRO_SEC: float = 3.2
# --- Hør og finn: big, front-facing letters on round sand tiles
const FIND_LETTER_M: float = 2.8  # glyph em-based height; x-height letters land at >= 260 px
const FIND_SPACING_M: float = 3.7
const FIND_CAM_DISTANCE: float = 7.2
const FIND_CAM_PITCH_DEG: float = 24.0
const FIND_CAM_LIFT: float = 1.3
const FIND_CAM_YAW_DEG: float = 30.0  # along the beach; the ship with the jar in the bay behind
# --- The ship in the bay and what each found sound brings back (SCRIPT.md 2d)
const SHIP_ANGLE_DEG: float = 182.0  # the west bay, seen past the Hør og finn beach
const SHIP_OFFSHORE_M: float = 6.0
# Spots behind the letter row, seen from the Hør og finn camera once the letters
# have sunk. label -> (coast angle deg, inset, lift) on the main island; "s" =
# (ahead m, height m, right m) from the Hør og finn station along its view, low
# over the sea so it rises at the horizon; "l" = (x, unused, z) on the islet.
const THING_SPOTS: Dictionary = {
	"a": Vector3(155.0, 0.9, 0.0),
	"s": Vector3(40.0, 3.2, -4.0),
	"i": Vector3(125.0, 0.6, 0.0),
	"l": Vector3(-0.6, 0.0, 0.9),
	"o": Vector3(128.0, 0.92, 0.0),
	"m": Vector3(138.0, 0.7, 0.0),
}
const THING_SCALES: Dictionary = {"a": 1.1, "s": 1.6, "i": 0.75, "l": 0.75, "o": 0.7, "m": 1.0}
const LETTER_FLY_SEC: float = 1.3
const LETTER_FLY_ARC_M: float = 1.5  # low arc: the find view shows little sky
const THING_CAM_SEC: float = 1.1
const TILE_RADIUS_M: float = 1.35
const TILE_TOP_M: float = 0.12
# --- Ordbroa: close camera, one big slot per letter, stones on a raft
# camera target = bridge middle + offset (toward the islet)
const BRIDGE_CAM_OFFSET: Vector3 = Vector3(1.0, 0.3, 0.5)
const BRIDGE_CAM_DISTANCE: float = 5.4  # 6-letter words still get >= 160 px slots
const BRIDGE_CAM_PITCH_DEG: float = 34.0
const BRIDGE_DECK_Y: float = 0.42
const BRIDGE_END_MARGIN_M: float = 0.35
const BRIDGE_PITCH_MIN_M: float = 1.05
const BRIDGE_PITCH_MAX_M: float = 1.7
const BRIDGE_SLOT_FILL: float = 0.9  # plank/slot width as a share of the pitch
const BRIDGE_PITCH_MULTI_MIN_M: float = 0.7  # several words share the bridge: smaller planks
const BRIDGE_FULL_PITCH_M: float = 1.3  # below this pitch planks and letters shrink with it
const BRIDGE_WORD_GAP_M: float = 0.3  # plain deck between two words
## Where each bridge word's picture shows while its story line plays (OrdBro):
## on = sky (along the ray, dist m), water or ground (under the screen point,
## screen = fraction of the viewport), pip (camera-local, next to Pip).
const WORD_PICTURES: Dictionary = {
	"sun": {"on": "sky", "screen": Vector2(0.46, 0.13), "dist": 16.0, "scale": 1.2},
	"seal": {"on": "water", "screen": Vector2(0.4, 0.42), "scale": 0.9},
	"boat": {"on": "water", "screen": Vector2(0.42, 0.27), "scale": 0.8},
	"food": {"on": "ground", "screen": Vector2(0.95, 0.4), "scale": 0.6},
	"book": {"on": "pip", "off": Vector3(1.5, 0.2, 0.0), "scale": 0.8},
}
const BRIDGE_STONE_SCALE: float = 1.1
const BRIDGE_STONE_GAP_PX: float = 340.0
const BRIDGE_STONE_CROWD_SCALE: float = 0.85  # a crowded raft (narrower gaps) gets smaller stones
const BRIDGE_STONE_ROW_FROM_BOTTOM_PX: float = 160.0
const RAFT_Y: float = 0.3
const PICTURE_FROM_RIGHT_PX: float = 290.0  # the waiting picture's feet on screen
const PICTURE_FEET_Y: float = 0.6
const PICTURE_SCALE: float = 0.72
# lam first (the hub line and the found lamb point at it); is when m is not open yet
const BRIDGE_FIRST_WORDS: Array[String] = ["w_lam", "w_lama", "w_is"]
# Scaffold by the child's finished bridges: the last `missing` letters are
# empty, the rest pre-placed; `distractors` extra stones (owner report 2026-10-03).
const BRIDGE_STAGES: Array[Dictionary] = [
	{"after": 0, "missing": 1, "distractors": 0},
	{"after": 1, "missing": 1, "distractors": 1},
	{"after": 3, "missing": 2, "distractors": 0},
	{"after": 5, "missing": 2, "distractors": 1},
	{"after": 7, "missing": 99, "distractors": 0},
	{"after": 9, "missing": 99, "distractors": 1},
]
# --- Opening story
const HYSJ_SCALE: float = 1.5  # big and readable from the story camera
const STORY_SHIP_GLIDE_M: float = 45.0  # the ship glides in from this far along the coast
# --- Pip
const PIP_SCREEN_OFFSET: Vector3 = Vector3(-2.85, -1.15, -5.0)  # camera-local home spot
const PIP_BRIDGE_OFFSET: Vector3 = Vector3(-3.0, -0.75, -5.0)  # over the water by the bridge
const PIP_FOLLOW_RATE: float = 4.0
const PIP_BOB_HEIGHT: float = 0.12
const PIP_BOB_HZ: float = 0.55
# --- Letters (DESIGN 7.3)
const LETTER_HEIGHT_M: float = 1.6
const LETTER_BOB_M: float = 0.15
const LETTER_BOB_HZ: float = 0.6
const LETTER_SWAY_DEG: float = 20.0
const HALO_PULSE_HZ: float = 0.8
const HINT_PULSE_PERIOD_SEC: float = 1.2
# --- Activities
const ITEMS_PER_VISIT: Dictionary = {"hor_og_finn": 4, "skriv": 2, "ordbro": 2}
const MAX_CHOICES: Dictionary = {"hor_og_finn": 3, "skriv": 1, "ordbro": 4}
const PRAISE_EVERY_N_CORRECT: int = 3
const TAP_RADIUS_MIN_PX: float = 120.0  # 1.5x the visual (DESIGN 4)
const WRONG_WOBBLE_DEG: float = 6.0
const WRONG_WOBBLE_SEC: float = 0.4
const FREEZE_AFTER_RANDOM_TAPS_SEC: float = 1.5
const ZONE_RESTORE_SEC: float = 2.5
const PLANT_STAGGER_SEC: float = 0.05
# Slice: all six sounds are open from the start so every station has content.
# The real gate (two sounds, then one per session) is in the engine and tested.
const SLICE_OPEN_ALL_SOUNDS: bool = true
# --- UI sizes (DESIGN 4, px at 1080 tall)
const BTN_PRIMARY_PX: float = 260.0
const BTN_SECONDARY_PX: float = 200.0
const BTN_MIN_PX: float = 176.0
const SAFE_MARGIN_PX: float = 64.0
const PARENT_HOLD_SEC: float = 3.0
const PARENT_WRONG_LIMIT: int = 3
const PARENT_LOCK_SEC: float = 60.0
