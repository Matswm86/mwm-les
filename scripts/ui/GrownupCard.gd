class_name GrownupCard
extends Control
## Read to a grown-up (GDD 10.4): a big card with today's words. Tapping a
## word plays it. The adult holds "Voksen: Hørt!" for 1.5 s, or the child
## taps the sleeping sun ("Ingen voksen nå"). No scoring, no penalty.

signal heard
signal no_adult

var words: Array[String] = []
var _word_labels: Array[Control] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(GameTune.INK, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var card: Panel = Panel.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = GameTune.UI_PANEL
	sb.set_corner_radius_all(48)
	sb.border_color = GameTune.INK
	sb.set_border_width_all(8)
	card.add_theme_stylebox_override("panel", sb)
	card.position = Vector2(260, 130)
	card.size = Vector2(1400, 620)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	var n: int = words.size()
	var slot_w: float = 1300.0 / float(maxi(n, 1))
	for i in n:
		var b: RoundButton = RoundButton.new().setup(
			176, GameTune.UI_PANEL, RoundButton.Icon.NONE, words[i]
		)
		b.rounded_rect = true
		b.set_label_size(150)
		b.set_label_color(GameTune.INK)
		b.color = Color(1.0, 0.97, 0.88)
		b.resize(Vector2(slot_w - 40.0, 300))
		b.position = Vector2(310 + slot_w * i, 290)
		b.pressed.connect(func() -> void: Voice.say(["ord_" + words[i]]))
		add_child(b)
		_word_labels.append(b)
	var adult: RoundButton = RoundButton.new().setup(
		176, GameTune.GO, RoundButton.Icon.NONE, "Voksen: Hørt!"
	)
	adult.rounded_rect = true
	adult.set_label_size(48)
	adult.resize(Vector2(460, 176))
	adult.hold_sec = LearnBalance.GROWNUP_HOLD_SEC
	adult.position = Vector2(1920 - 460 - 120, 1080 - 176 - 70)
	adult.held.connect(func() -> void: heard.emit())
	add_child(adult)
	var none: RoundButton = RoundButton.new().setup(
		GameTune.BTN_SECONDARY_PX, GameTune.SEA_BTN, RoundButton.Icon.SUN
	)
	none.position = Vector2(140, 1080 - GameTune.BTN_SECONDARY_PX - 60)
	none.pressed.connect(func() -> void: no_adult.emit())
	add_child(none)
	var cap: Label = Label.new()
	cap.text = "Ingen voksen nå"
	cap.add_theme_font_size_override("font_size", 34)
	cap.add_theme_color_override("font_color", Color(1, 1, 1))
	cap.position = Vector2(370, 1080 - 150)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cap)
