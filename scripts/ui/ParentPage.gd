class_name ParentPage
extends Control
## Parent area stub (GDD 10.3): per-sound status (no percentages, no grades),
## today's off-screen idea, the parent script and the privacy line.

signal closed

const STATUS_TEXT: Dictionary = {
	&"not_started": "ikke startet",
	&"practising": "øver",
	&"secure": "sikker",
}
const STATUS_DOTS: Dictionary = {&"not_started": 0, &"practising": 1, &"secure": 2}
const SCRIPT_LINES: Array[String] = [
	"Sitt sammen med barnet de siste minuttene.",
	"La barnet lese selv. Vent, ikke si ordet først.",
	"Står barnet fast: si den første lyden, ikke bokstavnavnet.",
	"Si hva barnet gjorde: «Du trakk sammen s-o-l til sol!»",
	"Gjør dagens forslag uten skjerm sammen.",
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg: ColorRect = ColorRect.new()
	bg.color = GameTune.UI_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_text("Fremgang", 64, Vector2(110, 60))
	var e: LearnEngine = Game.engine
	var y: float = 170.0
	var secure: Array[String] = []
	for sid: String in e.pack.unlock_order:
		var st: StringName = e.model.status(sid)
		var row: Panel = Panel.new()
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = GameTune.UI_PANEL
		sb.set_corner_radius_all(28)
		sb.border_color = Color(GameTune.INK, 0.25)
		sb.set_border_width_all(3)
		row.add_theme_stylebox_override("panel", sb)
		row.position = Vector2(110, y)
		row.size = Vector2(760, 112)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
		var letter: Label = _text(Game.label(sid), 84, Vector2(150, y - 6))
		letter.add_theme_color_override("font_outline_color", GameTune.GOLD)
		_text(str(STATUS_TEXT.get(st, "")), 44, Vector2(300, y + 26))
		var dots: int = int(STATUS_DOTS.get(st, 0))
		for k in 2:
			var d: ColorRect = ColorRect.new()
			d.color = GameTune.GOLD if k < dots else Color(GameTune.INK, 0.15)
			d.position = Vector2(760 + k * 46, y + 40)
			d.size = Vector2(34, 34)
			d.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(d)
		if st == &"secure":
			secure.append(Game.label(sid))
		y += 128.0
	var summary: String = "Barnet øver på lydene."
	if not secure.is_empty():
		summary = "Barnet kan lydene %s." % ", ".join(secure)
	_text(summary, 40, Vector2(110, y + 8))
	var col: VBoxContainer = VBoxContainer.new()
	col.position = Vector2(940, 170)
	col.custom_minimum_size = Vector2(860, 0)
	col.add_theme_constant_override("separation", 14)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	_col_text(col, "I dag", 52)
	_col_text(col, str(Game.offline_today.get("text", "Ingen forslag ennå.")), 36)
	_col_text(col, " ", 16)
	_col_text(col, "Slik hjelper du", 52)
	for i in SCRIPT_LINES.size():
		_col_text(col, "%d. %s" % [i + 1, SCRIPT_LINES[i]], 33)
	_col_text(col, " ", 16)
	_col_text(col, "Alt lagres bare på denne enheten. Ingenting sendes noe sted.", 33)
	var close: RoundButton = RoundButton.new().setup(
		GameTune.BTN_MIN_PX, GameTune.CORAL, RoundButton.Icon.CLOSE
	)
	Hud.place_top_right(close, GameTune.SAFE_MARGIN_PX * 0.6)
	close.pressed.connect(func() -> void: closed.emit())
	add_child(close)


func _text(t: String, px: int, pos: Vector2) -> Label:
	var l: Label = Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", GameTune.INK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _col_text(col: VBoxContainer, t: String, px: int) -> void:
	var l: Label = Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(860, 0)
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", GameTune.INK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(l)
