class_name GhostHand
extends Control
## A translucent cartoon hand that shows what to do (GDD 6.0 ghost-finger
## demo, and the last hint step). It taps a spot or drags from one spot to
## another, and loops until stop() is called. Positions are callables so the
## hand follows things that move (3D objects under a moving camera).

enum Kind { NONE, TAP, DRAG }

const TRAVEL_SEC: float = 1.2  # GDD 5.7 GHOST_FINGER_MOVE_SEC
const PRESS_SEC: float = 0.35
const REST_SEC: float = 0.7
const ALPHA: float = 0.72

var kind: Kind = Kind.NONE
var _from: Callable
var _to: Callable
var _t: float = 0.0
var _pos: Vector2 = Vector2.ZERO
var _press: float = 0.0  # 0 = finger up, 1 = pressed
var _fade: float = 0.0
var _ripple: float = -1.0
var _ripple_at: Vector2 = Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func showing() -> bool:
	return kind != Kind.NONE


## Tap `at` again and again.
func tap(at: Callable) -> void:
	kind = Kind.TAP
	_from = at
	_to = at
	_t = 0.0
	set_process(true)


## Drag from `from` to `to` again and again.
func drag(from: Callable, to: Callable) -> void:
	kind = Kind.DRAG
	_from = from
	_to = to
	_t = 0.0
	set_process(true)


func stop() -> void:
	kind = Kind.NONE
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	var a: Vector2 = _from.call()
	var b: Vector2 = _to.call()
	if kind == Kind.TAP:
		var cycle: float = 0.5 + PRESS_SEC * 2.0 + REST_SEC
		var u: float = fmod(_t, cycle)
		_fade = clampf(u / 0.25, 0.0, 1.0) * clampf((cycle - u) / 0.25, 0.0, 1.0)
		_press = 0.0
		if u > 0.5 and u < 0.5 + PRESS_SEC * 2.0:
			_press = sin((u - 0.5) / (PRESS_SEC * 2.0) * PI)
			if _ripple < 0.0:
				_ripple = 0.0
				_ripple_at = a
		_pos = a + Vector2(30, 40) * (1.0 - _press)
	else:
		var cycle2: float = 0.4 + PRESS_SEC + TRAVEL_SEC + PRESS_SEC + REST_SEC
		var u2: float = fmod(_t, cycle2)
		_fade = clampf(u2 / 0.3, 0.0, 1.0) * clampf((cycle2 - u2) / 0.3, 0.0, 1.0)
		var t1: float = 0.4
		var t2: float = t1 + PRESS_SEC
		var t3: float = t2 + TRAVEL_SEC
		var t4: float = t3 + PRESS_SEC
		if u2 < t1:
			_pos = a + Vector2(30, 40)
			_press = 0.0
		elif u2 < t2:
			_press = (u2 - t1) / PRESS_SEC
			_pos = a + Vector2(30, 40) * (1.0 - _press)
		elif u2 < t3:
			_press = 1.0
			_pos = a.lerp(b, smoothstep(0.0, 1.0, (u2 - t2) / TRAVEL_SEC))
		elif u2 < t4:
			_press = 1.0 - (u2 - t3) / PRESS_SEC
			_pos = b + Vector2(30, 40) * (1.0 - _press)
		else:
			_press = 0.0
			_pos = b + Vector2(30, 40)
	if _ripple >= 0.0:
		_ripple += delta
		if _ripple > 0.7:
			_ripple = -1.0
	queue_redraw()


## The fingertip is at _pos; the hand hangs below-right of it.
func _draw() -> void:
	if kind == Kind.NONE or _fade <= 0.0:
		return
	var al: float = ALPHA * _fade
	if _ripple >= 0.0:
		var r: float = 40.0 + _ripple * 160.0
		draw_arc(_ripple_at, r, 0.0, TAU, 40, Color(1, 1, 1, al * (1.0 - _ripple / 0.7)), 8.0)
	var s: float = 1.0 - 0.1 * _press
	var tip: Vector2 = _pos
	var ink: Color = Color(GameTune.INK, al)
	var skin: Color = Color(1, 1, 1, al)
	# index finger
	var f_top: Vector2 = tip + Vector2(0, 14) * s
	var f_bot: Vector2 = tip + Vector2(8, 120) * s
	_capsule(f_top, f_bot, 30.0 * s, ink, skin)
	# palm with three folded fingers and a thumb
	var palm: Vector2 = tip + Vector2(48, 175) * s
	draw_circle(palm, 76.0 * s, ink)
	_capsule(tip + Vector2(-38, 150) * s, tip + Vector2(-58, 108) * s, 26.0 * s, ink, skin)
	for k in 3:
		var kx: float = 32.0 + 34.0 * float(k)
		draw_circle(tip + Vector2(kx, 112 + 8 * k) * s, 30.0 * s, ink)
	draw_circle(palm, 70.0 * s, skin)
	for k in 3:
		var kx2: float = 32.0 + 34.0 * float(k)
		draw_circle(tip + Vector2(kx2, 112 + 8 * k) * s, 24.0 * s, skin)
	_capsule(f_top, f_bot, 24.0 * s, skin, skin)
	draw_circle(tip + Vector2(0, 22) * s, 10.0 * s, Color(GameTune.PIP_CHEEK, al * 0.8))


func _capsule(a: Vector2, b: Vector2, r: float, outer: Color, inner: Color) -> void:
	draw_line(a, b, outer, (r + 6.0) * 2.0)
	draw_circle(a, r + 6.0, outer)
	draw_circle(b, r + 6.0, outer)
	draw_line(a, b, inner, r * 2.0)
	draw_circle(a, r, inner)
	draw_circle(b, r, inner)
