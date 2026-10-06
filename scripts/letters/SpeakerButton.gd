class_name SpeakerButton
extends Control
## Big round speaker button: replays the target sound. Silent itself (no
## click sound, so it never talks over a letter). Touch only.

signal pressed

const FILL: Color = Color(0.11, 0.39, 0.72)
const INK: Color = Color(0.11, 0.17, 0.27)
const ICON: Color = Color(1, 1, 1)


func setup(side: float) -> SpeakerButton:
	custom_minimum_size = Vector2(side, side)
	size = Vector2(side, side)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	return self


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event as InputEventScreenTouch
		accept_event()
		if t.pressed:
			var tw: Tween = create_tween()
			tw.tween_property(self, "scale", Vector2.ONE * 0.92, 0.08)
			tw.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
		elif Rect2(Vector2.ZERO, size).has_point(t.position):
			pressed.emit()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5
	draw_circle(c + Vector2(0, 8), r - 2.0, Color(INK, 0.25))
	draw_circle(c, r - 2.0, INK)
	draw_circle(c, r - 9.0, FILL)
	var s: float = r * 0.5
	var body: PackedVector2Array = [
		c + Vector2(-s * 0.9, -s * 0.35),
		c + Vector2(-s * 0.4, -s * 0.35),
		c + Vector2(s * 0.15, -s * 0.85),
		c + Vector2(s * 0.15, s * 0.85),
		c + Vector2(-s * 0.4, s * 0.35),
		c + Vector2(-s * 0.9, s * 0.35)
	]
	draw_colored_polygon(body, ICON)
	draw_arc(c + Vector2(s * 0.2, 0), s * 0.45, -0.9, 0.9, 16, ICON, s * 0.14, true)
	draw_arc(c + Vector2(s * 0.2, 0), s * 0.8, -0.9, 0.9, 16, ICON, s * 0.14, true)
