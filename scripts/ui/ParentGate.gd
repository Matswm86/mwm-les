class_name ParentGate
extends Control
## Parent gate (GDD 10.3): hold a button for 3 s, then type the answer to a
## two-digit sum with carry. Three wrong answers lock the pad for 60 s.

signal passed
signal closed

var _a: int = 0
var _b: int = 0
var _typed: String = ""
var _wrong: int = 0
var _locked_until: int = 0
var _info: Label
var _sum: Label
var _answer: Label
var _hold: RoundButton
var _pad: GridContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg: ColorRect = ColorRect.new()
	bg.color = GameTune.UI_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_make_sum()
	var title: Label = _label("For voksne", 64, Vector2(120, 110))
	title.add_theme_color_override("font_color", GameTune.INK)
	_info = _label("Hold knappen inne i 3 sekunder.", 44, Vector2(120, 210))
	_hold = RoundButton.new().setup(GameTune.BTN_PRIMARY_PX, GameTune.GO, RoundButton.Icon.CHECK)
	_hold.hold_sec = GameTune.PARENT_HOLD_SEC
	_hold.position = Vector2(220, 380)
	_hold.held.connect(_on_held)
	add_child(_hold)
	_sum = _label("Skriv svaret på %d + %d" % [_a, _b], 52, Vector2(120, 320))
	_sum.visible = false
	_answer = _label("", 96, Vector2(120, 430))
	_answer.visible = false
	_pad = GridContainer.new()
	_pad.columns = 3
	_pad.add_theme_constant_override("h_separation", 28)
	_pad.add_theme_constant_override("v_separation", 24)
	_pad.position = Vector2(1080, 120)
	_pad.visible = false
	add_child(_pad)
	for k: String in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "<", "0", "OK"]:
		var b: RoundButton
		if k == "<":
			b = RoundButton.new().setup(GameTune.BTN_MIN_PX, GameTune.CORAL, RoundButton.Icon.BACK)
		elif k == "OK":
			b = RoundButton.new().setup(GameTune.BTN_MIN_PX, GameTune.GO, RoundButton.Icon.CHECK)
		else:
			b = RoundButton.new().setup(
				GameTune.BTN_MIN_PX, GameTune.UI_PANEL, RoundButton.Icon.NUMBER, k
			)
			b.set_label_color(GameTune.INK)
			b.set_label_size(72)
		b.pressed.connect(_on_key.bind(k))
		_pad.add_child(b)
	var close: RoundButton = RoundButton.new().setup(
		GameTune.BTN_MIN_PX, GameTune.CORAL, RoundButton.Icon.CLOSE
	)
	Hud.place_top_right(close, GameTune.SAFE_MARGIN_PX * 0.6)
	close.pressed.connect(func() -> void: closed.emit())
	add_child(close)
	Voice.say(["gate_1", "gate_2"])


func _label(t: String, px: int, pos: Vector2) -> Label:
	var l: Label = Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", GameTune.INK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _make_sum() -> void:
	# two-digit numbers whose ones digits carry
	_a = randi_range(12, 79)
	var ones: int = randi_range(maxi(10 - _a % 10, 1), 9)
	_b = randi_range(1, 8) * 10 + ones
	if (_a % 10) + (_b % 10) < 10:
		_b += 10 - ((_a % 10) + (_b % 10))


func _on_held() -> void:
	_hold.visible = false
	_info.text = "Bruk tallene til høyre."
	_sum.visible = true
	_answer.visible = true
	_pad.visible = true


func _on_key(k: String) -> void:
	if Time.get_ticks_msec() < _locked_until:
		return
	if k == "<":
		_typed = _typed.substr(0, maxi(_typed.length() - 1, 0))
	elif k == "OK":
		if _typed == str(_a + _b):
			passed.emit()
			return
		_wrong += 1
		_typed = ""
		if _wrong >= GameTune.PARENT_WRONG_LIMIT:
			_wrong = 0
			_locked_until = Time.get_ticks_msec() + int(GameTune.PARENT_LOCK_SEC * 1000.0)
			_info.text = "Prøv igjen om ett minutt."
			_make_sum()
			_sum.text = "Skriv svaret på %d + %d" % [_a, _b]
	elif _typed.length() < 3:
		_typed += k
	_answer.text = _typed


## Test hook for the screenshot bot: the current correct answer.
func answer() -> int:
	return _a + _b
