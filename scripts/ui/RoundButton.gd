class_name RoundButton
extends Control
## Big round icon button for small hands (DESIGN 4). Touch only
## (InputEventScreenTouch; mouse clicks arrive as emulated touches).
## Pressed: scale 0.92, bounce back. Optional hold-to-confirm with a ring.

signal pressed
signal held

enum Icon { NONE, SPEAKER, HOUSE, PARENT, CHECK, SUN, CLOSE, BACK, NUMBER }

var color: Color = GameTune.SEA_BTN
var icon_color: Color = Color(1, 1, 1)
var icon: Icon = Icon.NONE
var text: String = ""
var font_size: int = 64
var hold_sec: float = 0.0
var rounded_rect: bool = false
var _hold_t: float = -1.0
var _label: Label


func setup(p_size: float, p_color: Color, p_icon: Icon, p_text: String = "") -> RoundButton:
	custom_minimum_size = Vector2(p_size, p_size)
	size = Vector2(p_size, p_size)
	pivot_offset = size * 0.5
	color = p_color
	icon = p_icon
	text = p_text
	mouse_filter = Control.MOUSE_FILTER_STOP
	if text != "":
		_label = Label.new()
		_label.text = text
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_label.add_theme_font_size_override("font_size", font_size)
		_label.add_theme_color_override("font_color", icon_color)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)
	return self


func set_label_size(px: int) -> void:
	font_size = px
	if _label:
		_label.add_theme_font_size_override("font_size", px)


func set_label_color(c: Color) -> void:
	icon_color = c
	if _label:
		_label.add_theme_color_override("font_color", c)
	queue_redraw()


func resize(s: Vector2) -> void:
	custom_minimum_size = s
	size = s
	pivot_offset = s * 0.5
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event as InputEventScreenTouch
		accept_event()
		if t.pressed:
			_press_anim()
			Voice.sfx("pop")
			if hold_sec > 0.0:
				_hold_t = 0.0
		else:
			if hold_sec > 0.0:
				_hold_t = -1.0
				queue_redraw()
			elif Rect2(Vector2.ZERO, size).has_point(t.position):
				pressed.emit()


func _process(delta: float) -> void:
	if _hold_t < 0.0:
		return
	_hold_t += delta
	queue_redraw()
	if _hold_t >= hold_sec:
		_hold_t = -1.0
		queue_redraw()
		held.emit()


func _press_anim() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * 0.92, 0.08)
	tw.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5
	if rounded_rect:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = color
		sb.set_corner_radius_all(int(minf(size.y * 0.3, 48.0)))
		sb.border_color = GameTune.INK
		sb.set_border_width_all(6)
		sb.shadow_color = Color(GameTune.INK, 0.25)
		sb.shadow_offset = Vector2(0, 8)
		sb.shadow_size = 2
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
	else:
		draw_circle(c + Vector2(0, 8), r - 2.0, Color(GameTune.INK, 0.25))
		draw_circle(c, r - 2.0, GameTune.INK)
		draw_circle(c, r - 8.0, color)
	if _hold_t >= 0.0 and hold_sec > 0.0:
		var k: float = clampf(_hold_t / hold_sec, 0.0, 1.0)
		var rr: float = (minf(size.x, size.y) * 0.5) - 14.0
		draw_arc(c, rr, -PI * 0.5, -PI * 0.5 + TAU * k, 48, GameTune.GOLD, 14.0, true)
	_draw_icon(c, r * 0.5)


func _draw_icon(c: Vector2, s: float) -> void:
	var ic: Color = icon_color
	match icon:
		Icon.SPEAKER:
			var body: PackedVector2Array = [
				c + Vector2(-s * 0.9, -s * 0.35),
				c + Vector2(-s * 0.4, -s * 0.35),
				c + Vector2(s * 0.15, -s * 0.85),
				c + Vector2(s * 0.15, s * 0.85),
				c + Vector2(-s * 0.4, s * 0.35),
				c + Vector2(-s * 0.9, s * 0.35)
			]
			draw_colored_polygon(body, ic)
			draw_arc(c + Vector2(s * 0.2, 0), s * 0.45, -0.9, 0.9, 16, ic, s * 0.14, true)
			draw_arc(c + Vector2(s * 0.2, 0), s * 0.8, -0.9, 0.9, 16, ic, s * 0.14, true)
		Icon.HOUSE:
			draw_colored_polygon(
				[
					c + Vector2(0, -s * 0.95),
					c + Vector2(s * 0.95, -s * 0.05),
					c + Vector2(-s * 0.95, -s * 0.05)
				],
				ic
			)
			draw_rect(Rect2(c + Vector2(-s * 0.65, -s * 0.1), Vector2(s * 1.3, s * 0.95)), ic)
			draw_rect(Rect2(c + Vector2(-s * 0.18, s * 0.3), Vector2(s * 0.36, s * 0.55)), color)
		Icon.PARENT:
			draw_circle(c + Vector2(-s * 0.35, -s * 0.45), s * 0.28, ic)
			draw_circle(c + Vector2(s * 0.45, -s * 0.2), s * 0.2, ic)
			draw_rect(Rect2(c + Vector2(-s * 0.7, -s * 0.1), Vector2(s * 0.7, s * 0.95)), ic)
			draw_rect(Rect2(c + Vector2(s * 0.2, s * 0.1), Vector2(s * 0.5, s * 0.75)), ic)
		Icon.CHECK:
			draw_polyline(
				[
					c + Vector2(-s * 0.7, 0),
					c + Vector2(-s * 0.15, s * 0.55),
					c + Vector2(s * 0.75, -s * 0.55)
				],
				ic,
				s * 0.28,
				true
			)
		Icon.SUN:
			draw_circle(c + Vector2(0, s * 0.2), s * 0.5, ic)
			draw_rect(Rect2(c + Vector2(-s, s * 0.2), Vector2(s * 2.0, s * 0.8)), color)
			for k in 5:
				var a: float = PI + PI * float(k + 1) / 6.0
				var d: Vector2 = Vector2(cos(a), sin(a))
				draw_line(
					c + Vector2(0, s * 0.2) + d * s * 0.65,
					c + Vector2(0, s * 0.2) + d * s * 0.95,
					ic,
					s * 0.14
				)
			draw_line(c + Vector2(-s * 0.9, s * 0.3), c + Vector2(s * 0.9, s * 0.3), ic, s * 0.12)
		Icon.CLOSE:
			draw_line(c + Vector2(-s * 0.6, -s * 0.6), c + Vector2(s * 0.6, s * 0.6), ic, s * 0.28)
			draw_line(c + Vector2(s * 0.6, -s * 0.6), c + Vector2(-s * 0.6, s * 0.6), ic, s * 0.28)
		Icon.BACK:
			draw_colored_polygon(
				[
					c + Vector2(-s * 0.9, 0),
					c + Vector2(-s * 0.2, -s * 0.6),
					c + Vector2(-s * 0.2, s * 0.6)
				],
				ic
			)
			draw_rect(Rect2(c + Vector2(-s * 0.25, -s * 0.22), Vector2(s * 1.1, s * 0.44)), ic)
		_:
			pass
