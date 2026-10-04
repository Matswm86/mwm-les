class_name WritePad
extends Control
## The wet-sand writing area for "watch then write" (GDD 0.2, 6.1). Draws
## Pip's model letter stroke by stroke, the child's finger ink, the start-dot
## and trace hints, and the compare overlay. Input comes from the activity.

const DOT_STEP_PX: float = 38.0

var model: Array[PackedVector2Array] = []  # unit box, y down
var model_progress: float = 0.0  # strokes drawn (1.5 = first done, half of second)
var model_alpha: float = 0.0
var ink: Array[PackedVector2Array] = []  # screen px
var ink_alpha: float = 1.0
var ink_gold: float = 0.0
var show_start_dot: bool = false
var show_trace: bool = false
var compare_alpha: float = 0.0
var patch_alpha: float = 0.0
var wash: float = -1.0  # story beat: a wave sweeps over the sand, 0 -> 1 (-1 = off)
var box: Rect2
var _t: float = 0.0
var _grain: PackedVector2Array = PackedVector2Array()
var _grain_col: PackedColorArray = PackedColorArray()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h: float = 1080.0 * LearnBalance.WRITE_LETTER_HEIGHT_FRAC
	box = Rect2(Vector2(1040.0 - h * 0.5, 560.0 - h * 0.5), Vector2(h, h))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	var pr: Rect2 = patch_rect()
	for i in 260:
		_grain.append(pr.position + Vector2(rng.randf() * pr.size.x, rng.randf() * pr.size.y))
		_grain_col.append(
			Color(1, 1, 1, 0.10) if rng.randf() < 0.5 else Color(0.35, 0.22, 0.1, 0.10)
		)


func patch_rect() -> Rect2:
	return box.grow(80.0)


func to_screen(u: Vector2) -> Vector2:
	return box.position + u * box.size.y


func model_start() -> Vector2:
	if model.is_empty() or model[0].is_empty():
		return box.get_center()
	return to_screen(model[0][0])


func inside(pos: Vector2) -> bool:
	return patch_rect().has_point(pos)


func begin_stroke(pos: Vector2) -> void:
	ink.append(PackedVector2Array([pos]))
	queue_redraw()


func extend_stroke(pos: Vector2) -> void:
	if ink.is_empty():
		return
	var s: PackedVector2Array = ink[ink.size() - 1]
	if s[s.size() - 1].distance_to(pos) >= 4.0:
		s.append(pos)
		ink[ink.size() - 1] = s
		queue_redraw()


func clear_ink() -> void:
	ink.clear()
	ink_alpha = 1.0
	ink_gold = 0.0
	queue_redraw()


func ink_bounds() -> Rect2:
	var all: PackedVector2Array = PackedVector2Array()
	for s: PackedVector2Array in ink:
		all.append_array(s)
	return WriteCheck.bounds(all)


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	if patch_alpha <= 0.0:
		return
	var pr: Rect2 = patch_rect()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(GameTune.SAND_WET, 0.97 * patch_alpha)
	sb.set_corner_radius_all(140)
	sb.border_color = Color(GameTune.SAND, 0.9 * patch_alpha)
	sb.set_border_width_all(18)
	sb.shadow_color = Color(0.4, 0.28, 0.12, 0.18 * patch_alpha)
	sb.shadow_size = 24
	draw_style_box(sb, pr)
	for i in _grain.size():
		var c: Color = _grain_col[i]
		c.a *= patch_alpha
		draw_circle(_grain[i], 3.0, c)
	if show_trace:
		_draw_trace()
	_draw_ink()
	if model_alpha > 0.0:
		_draw_model()
	if compare_alpha > 0.0:
		_draw_compare()
	if wash >= 0.0:
		_draw_wash()
	if show_start_dot:
		var p: Vector2 = model_start()
		var r: float = 65.0 * (1.0 + 0.08 * sin(_t * TAU / GameTune.HINT_PULSE_PERIOD_SEC))
		draw_circle(p, r, Color(GameTune.GOLD, 0.35))
		_draw_dotted_circle(p, r * 0.8)
		draw_circle(p, 16.0, GameTune.GOLD)


## A wave band (sea blue with a white foam edge) crossing the patch left to
## right, clipped to the patch.
func _draw_wash() -> void:
	var pr: Rect2 = patch_rect().grow(-10.0)
	var front: float = lerpf(pr.position.x - 120.0, pr.end.x + 420.0, wash)
	var foam: PackedVector2Array = PackedVector2Array()
	var steps: int = 24
	for k in steps + 1:
		var y: float = lerpf(pr.position.y, pr.end.y, float(k) / float(steps))
		var x: float = front + 26.0 * sin(y * 0.03 + _t * 6.0)
		foam.append(Vector2(clampf(x, pr.position.x, pr.end.x), y))
	var back: float = clampf(front - 420.0, pr.position.x, pr.end.x)
	var water: PackedVector2Array = PackedVector2Array()
	water.append(Vector2(back, pr.end.y))
	water.append(Vector2(back, pr.position.y))
	water.append_array(foam)
	if foam[0].x - back > 2.0 or foam[foam.size() - 1].x - back > 2.0:
		draw_colored_polygon(water, Color(GameTune.SEA_SHALLOW, 0.85))
	if front > pr.position.x and front < pr.end.x + 30.0:
		draw_polyline(foam, Color(GameTune.FOAM, 0.95), 30.0, true)


func _draw_dotted_circle(c: Vector2, r: float) -> void:
	for k in 14:
		var a: float = TAU * float(k) / 14.0 + _t * 0.6
		draw_circle(c + Vector2(cos(a), sin(a)) * r, 6.0, GameTune.INK)


func _draw_trace() -> void:
	for s: PackedVector2Array in model:
		var pts: PackedVector2Array = _scaled(s)
		var acc: float = 0.0
		for i in range(1, pts.size()):
			var a: Vector2 = pts[i - 1]
			var b: Vector2 = pts[i]
			var seg: float = a.distance_to(b)
			while acc <= seg:
				draw_circle(a.lerp(b, acc / maxf(seg, 0.001)), 9.0, Color(GameTune.INK, 0.45))
				acc += DOT_STEP_PX
			acc -= seg
		if pts.size() >= 2:
			_draw_arrow(pts[0], pts[1])


func _draw_arrow(a: Vector2, b: Vector2) -> void:
	var d: Vector2 = (b - a).normalized()
	var n: Vector2 = Vector2(-d.y, d.x)
	var tip: Vector2 = a + d * 70.0
	draw_colored_polygon(
		[tip, tip - d * 26.0 + n * 16.0, tip - d * 26.0 - n * 16.0], Color(GameTune.SEA_BTN, 0.8)
	)


func _draw_ink() -> void:
	if ink_alpha <= 0.0:
		return
	var groove: Color = Color(GameTune.SAND_WET.darkened(0.3), ink_alpha)
	var glow: Color = Color(1.0, 0.86, 0.5, ink_alpha).lerp(
		Color(GameTune.GOLD, ink_alpha), ink_gold
	)
	for s: PackedVector2Array in ink:
		if s.size() == 1:
			draw_circle(s[0], 23.0, groove)
			draw_circle(s[0], 12.0, glow)
			continue
		draw_polyline(s, groove, 46.0, true)
		_round_caps(s, 23.0, groove)
		draw_polyline(s, glow, 22.0 + 12.0 * ink_gold, true)
		_round_caps(s, 11.0 + 6.0 * ink_gold, glow)


func _round_caps(s: PackedVector2Array, r: float, c: Color) -> void:
	for i in s.size():
		if i == 0 or i == s.size() - 1 or i % 3 == 0:
			draw_circle(s[i], r, c)


func _draw_model() -> void:
	var outer: Color = Color(GameTune.GOLD, 0.35 * model_alpha)
	var core: Color = Color(GameTune.GOLD, model_alpha)
	var hot: Color = Color(1.0, 0.97, 0.8, model_alpha)
	var tip: Vector2 = Vector2(-1, -1)
	for si in model.size():
		var k: float = clampf(model_progress - float(si), 0.0, 1.0)
		if k <= 0.0:
			continue
		var pts: PackedVector2Array = _partial(_scaled(model[si]), k)
		if pts.size() == 1:
			draw_circle(pts[0], 26.0, core)
		else:
			draw_polyline(pts, outer, 70.0, true)
			_round_caps(pts, 35.0, outer)
			draw_polyline(pts, core, 36.0, true)
			_round_caps(pts, 18.0, core)
			draw_polyline(pts, hot, 10.0, true)
		if k < 1.0:
			tip = pts[pts.size() - 1]
	if tip.x >= 0.0:
		for k2 in 6:
			var a: float = TAU * float(k2) / 6.0 + _t * 4.0
			draw_line(
				tip,
				tip + Vector2(cos(a), sin(a)) * 58.0,
				Color(1, 0.95, 0.6, 0.6 * model_alpha),
				5.0
			)
		# the pen tip: a solid fingertip dot the eye can follow
		draw_circle(tip, 34.0, Color(GameTune.INK, 0.85 * model_alpha))
		draw_circle(tip, 28.0, Color(1, 1, 1, model_alpha))
		draw_circle(tip, 12.0, Color(GameTune.GOLD, model_alpha))


func _draw_compare() -> void:
	var ib: Rect2 = ink_bounds()
	var mb: Rect2 = WriteCheck.bounds(WriteCheck.resample(model, 48))
	var ms: float = maxf(mb.size.x, mb.size.y)
	var k: float = maxf(ib.size.x, ib.size.y) / maxf(ms, 0.001)
	var c: Color = Color(GameTune.SEA_BTN, 0.85 * compare_alpha)
	for s: PackedVector2Array in model:
		var pts: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in s:
			pts.append((p - mb.get_center()) * k + ib.get_center())
		if pts.size() == 1:
			draw_circle(pts[0], 12.0, c)
		else:
			draw_polyline(pts, c, 18.0, true)


func _scaled(s: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in s:
		out.append(to_screen(p))
	return out


## The first fraction k (by length) of a polyline.
func _partial(pts: PackedVector2Array, k: float) -> PackedVector2Array:
	if k >= 1.0 or pts.size() < 2:
		return pts
	var total: float = 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	var want: float = total * k
	var out: PackedVector2Array = PackedVector2Array([pts[0]])
	var acc: float = 0.0
	for i in range(1, pts.size()):
		var seg: float = pts[i - 1].distance_to(pts[i])
		if acc + seg >= want:
			out.append(pts[i - 1].lerp(pts[i], (want - acc) / maxf(seg, 0.001)))
			return out
		acc += seg
		out.append(pts[i])
	return out
