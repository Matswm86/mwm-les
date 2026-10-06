class_name LetterTile
extends Control
## One big lowercase letter on a card. Touch only (mouse clicks arrive as
## emulated touches). The tile never plays sound itself: it emits `tapped`
## and the screen decides what to play.

signal tapped(tile: LetterTile)

const CARD: Color = Color(1.0, 0.98, 0.93)
const INK: Color = Color(0.11, 0.17, 0.27)
const GLOW: Color = Color(1.0, 0.76, 0.10)
const BORDER_PX: int = 8
const GLOW_PX: float = 22.0
const HALO: Color = Color(1.0, 0.95, 0.62)
const X_HEIGHT_EM: float = 0.5  # Andika lowercase height, share of font size

var letter: String = ""
var glow: float = 0.0:
	set(v):
		glow = v
		queue_redraw()
var label: Label
var _tw: Tween
var _base_y: float = 0.0


func setup(p_letter: String, side: float, font_px: int) -> LetterTile:
	letter = p_letter
	custom_minimum_size = Vector2(side, side)
	size = Vector2(side, side)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	label = Label.new()
	label.text = p_letter
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_font_size_override("font_size", font_px)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Same baseline on every tile, x-height centred in the card: the font's
	# line box is much taller than a lowercase letter, so plain centring
	# pushes the letter to the bottom edge.
	var font: Font = label.get_theme_font("font")
	var baseline: float = side * 0.5 + font_px * X_HEIGHT_EM * 0.5
	label.position = Vector2(0.0, baseline - font.get_ascent(font_px))
	label.size = Vector2(side, font.get_height(font_px))
	add_child(label)
	return self


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event as InputEventScreenTouch
		accept_event()
		if not t.pressed and Rect2(Vector2.ZERO, size).has_point(t.position):
			press()


## Same path a real touch takes (the headless test calls this).
func press() -> void:
	tapped.emit(self)


func _new_tween() -> Tween:
	if _tw and _tw.is_valid():
		_tw.kill()
	scale = Vector2.ONE
	rotation = 0.0
	position.y = _base_y
	_tw = create_tween()
	return _tw


func remember_place() -> void:
	_base_y = position.y


## Grows and glows while its held sound plays (first-time intro).
func pulse(sec: float) -> void:
	var edge: float = minf(0.25, sec * 0.3)
	var tw: Tween = _new_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE * 1.12, edge).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "glow", 1.0, edge)
	tw.chain().tween_interval(maxf(sec - edge * 2.0, 0.0))
	tw.chain().tween_property(self, "scale", Vector2.ONE, edge).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "glow", 0.0, edge)


## Right answer: glows gold and bounces.
func celebrate() -> void:
	var tw: Tween = _new_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "glow", 1.0, 0.15)
	tw.tween_property(self, "scale", Vector2.ONE * 1.15, 0.15)
	tw.tween_property(self, "position:y", _base_y - 50.0, 0.18).set_ease(Tween.EASE_OUT)
	(
		tw
		. chain()
		. tween_property(self, "position:y", _base_y, 0.35)
		. set_trans(Tween.TRANS_BOUNCE)
		. set_ease(Tween.EASE_OUT)
	)


## Wrong answer: a short side-to-side wobble.
func wobble() -> void:
	var tw: Tween = _new_tween()
	for a: float in [-0.12, 0.10, -0.07, 0.04, 0.0]:
		tw.tween_property(self, "rotation", a, 0.08).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	if glow > 0.0:
		var g: StyleBoxFlat = StyleBoxFlat.new()
		g.bg_color = Color(HALO, 0.9 * glow)
		g.set_corner_radius_all(int(size.y * 0.16 + GLOW_PX))
		draw_style_box(g, r.grow(GLOW_PX * glow))
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = CARD
	sb.set_corner_radius_all(int(size.y * 0.16))
	sb.border_color = GLOW if glow > 0.5 else INK
	sb.set_border_width_all(BORDER_PX + int(6.0 * glow))
	sb.shadow_color = Color(INK, 0.25)
	sb.shadow_offset = Vector2(0, 10)
	sb.shadow_size = 4
	draw_style_box(sb, r)
