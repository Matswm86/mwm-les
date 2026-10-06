class_name WriteCheck
extends RefCounted
## Lenient shape check for "watch then write" (GDD 0.2, 6.1).
## Strokes are arrays of Vector2 in the model's 0-1 box (y down).
## Stroke order and direction are ignored on purpose.


static func strokes_from_json(raw: Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for s: Variant in raw:
		var pts: PackedVector2Array = PackedVector2Array()
		for p: Variant in s:
			var a: Array = p
			pts.append(Vector2(float(a[0]), float(a[1])))
		out.append(pts)
	return out


static func ink_length(strokes: Array[PackedVector2Array]) -> float:
	var total: float = 0.0
	for s: PackedVector2Array in strokes:
		for i in range(1, s.size()):
			total += s[i - 1].distance_to(s[i])
	return total


## n points spread evenly over the total length of all strokes (gaps not joined).
static func resample(strokes: Array[PackedVector2Array], n: int) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var total: float = ink_length(strokes)
	if total <= 0.0:
		for s: PackedVector2Array in strokes:
			for p: Vector2 in s:
				out.append(p)
		return out
	var step: float = total / float(maxi(n - 1, 1))
	var next_at: float = 0.0
	var walked: float = 0.0
	for s: PackedVector2Array in strokes:
		if s.size() == 1:
			out.append(s[0])
			continue
		for i in range(1, s.size()):
			var a: Vector2 = s[i - 1]
			var b: Vector2 = s[i]
			var seg: float = a.distance_to(b)
			while next_at <= walked + seg + 0.000001 and out.size() < n:
				var t: float = 0.0 if seg <= 0.0 else (next_at - walked) / seg
				out.append(a.lerp(b, clampf(t, 0.0, 1.0)))
				next_at += step
			walked += seg
	return out


static func bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var r: Rect2 = Rect2(points[0], Vector2.ZERO)
	for p: Vector2 in points:
		r = r.expand(p)
	return r


## Scale ink uniformly (by the larger side) into the model's box, centred.
static func fit_to(ink: Array[PackedVector2Array], model_box: Rect2) -> Array[PackedVector2Array]:
	var all: PackedVector2Array = PackedVector2Array()
	for s: PackedVector2Array in ink:
		all.append_array(s)
	var ib: Rect2 = bounds(all)
	var ink_side: float = maxf(ib.size.x, ib.size.y)
	var model_side: float = maxf(model_box.size.x, model_box.size.y)
	var k: float = 1.0 if ink_side <= 0.0 else model_side / ink_side
	var out: Array[PackedVector2Array] = []
	for s: PackedVector2Array in ink:
		var t: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in s:
			t.append((p - ib.get_center()) * k + model_box.get_center())
		out.append(t)
	return out


static func mean_nearest(a: PackedVector2Array, b: PackedVector2Array) -> float:
	if a.is_empty() or b.is_empty():
		return INF
	var sum: float = 0.0
	for p: Vector2 in a:
		var best: float = INF
		for q: Vector2 in b:
			best = minf(best, p.distance_squared_to(q))
		sum += sqrt(best)
	return sum / float(a.size())


static func mirrored(model: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for st: PackedVector2Array in model:
		var t: PackedVector2Array = PackedVector2Array()
		for q: Vector2 in st:
			t.append(Vector2(1.0 - q.x, q.y))
		out.append(t)
	return out


## Distance between the ink and a model as a fraction of the model's size,
## after fitting position and size. Order-, direction- and stroke-count-free;
## the best of a few small rotations, so a slanted letter is not punished.
## A separate dot (i) is a part of the letter: having one or not when the
## model does adds WRITE_DOT_MISMATCH. Ink with a stem at the bottom right
## (a) against a round model without one (o) adds WRITE_STEM_MISMATCH.
static func distance(ink: Array[PackedVector2Array], model: Array[PackedVector2Array]) -> float:
	var n: int = LearnBalance.WRITE_RESAMPLE_POINTS
	var model_pts: PackedVector2Array = resample(model, n)
	var box: Rect2 = bounds(model_pts)
	var best: float = INF
	var best_ink: Array[PackedVector2Array] = ink
	for deg: float in LearnBalance.WRITE_ROTATIONS_DEG:
		var fitted: Array[PackedVector2Array] = fit_to(rotated(ink, deg), box)
		var d: float = _shape_distance(resample(fitted, n), model_pts)
		if d < best:
			best = d
			best_ink = fitted
	if has_dot(ink) != has_dot(model):
		best += LearnBalance.WRITE_DOT_MISMATCH
	var round_model: bool = box.size.x >= box.size.y * LearnBalance.WRITE_STEM_MODEL_ASPECT
	# a stem where the model has none (an a written for o); a missed stem is
	# left to the shape distance, so a wobbly a is not punished twice
	if round_model and has_right_stem(best_ink) and not has_right_stem(model):
		best += LearnBalance.WRITE_STEM_MISMATCH
	return best


## Ink reaches the bottom-right corner of the letter's box: where the stem of
## a ends. An o stays well away from its box corners.
static func has_right_stem(strokes: Array[PackedVector2Array]) -> bool:
	var pts: PackedVector2Array = resample(strokes, LearnBalance.WRITE_RESAMPLE_POINTS * 2)
	var b: Rect2 = bounds(pts)
	var side: float = maxf(b.size.x, b.size.y)
	if side <= 0.0 or b.size.x < side * LearnBalance.WRITE_STEM_MIN_WIDTH_FRAC:
		return false  # thin letters (l, i) have no bowl to tell apart
	for q: Vector2 in pts:
		if q.distance_to(b.end) <= side * LearnBalance.WRITE_STEM_CORNER_FRAC:
			return true
	return false


static func rotated(ink: Array[PackedVector2Array], deg: float) -> Array[PackedVector2Array]:
	if is_zero_approx(deg):
		return ink
	var out: Array[PackedVector2Array] = []
	var r: float = deg_to_rad(deg)
	for st: PackedVector2Array in ink:
		var t: PackedVector2Array = PackedVector2Array()
		for q: Vector2 in st:
			t.append(q.rotated(r))
		out.append(t)
	return out


## A small separate mark in the top part of the letter (the dot on i).
static func has_dot(strokes: Array[PackedVector2Array]) -> bool:
	if strokes.size() < 2:
		return false
	var all: PackedVector2Array = PackedVector2Array()
	for st: PackedVector2Array in strokes:
		all.append_array(st)
	var b: Rect2 = bounds(all)
	var side: float = maxf(b.size.x, b.size.y)
	if side <= 0.0:
		return false
	for st: PackedVector2Array in strokes:
		var sb: Rect2 = bounds(st)
		var small: bool = maxf(sb.size.x, sb.size.y) <= side * LearnBalance.WRITE_DOT_MAX_FRAC
		var high: bool = sb.get_center().y <= b.position.y + b.size.y * 0.3
		if small and high:
			return true
	return false


static func _shape_distance(ink_pts: PackedVector2Array, model_pts: PackedVector2Array) -> float:
	var a: PackedFloat32Array = nearest_list(ink_pts, model_pts)
	var b: PackedFloat32Array = nearest_list(model_pts, ink_pts)
	# mean = overall shape; a high percentile = a missing or extra part (the
	# stem of a), which a mean alone washes out
	var mean: float = 0.5 * (_mean(a) + _mean(b))
	var pct: float = LearnBalance.WRITE_TAIL_PCT
	var tail: float = 0.5 * (_percentile(a, pct) + _percentile(b, pct))
	return lerpf(mean, tail, LearnBalance.WRITE_TAIL_WEIGHT)


static func nearest_list(a: PackedVector2Array, b: PackedVector2Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	for q: Vector2 in a:
		var best: float = INF
		for r: Vector2 in b:
			best = minf(best, q.distance_squared_to(r))
		out.append(sqrt(best))
	return out


static func _mean(v: PackedFloat32Array) -> float:
	if v.is_empty():
		return INF
	var t: float = 0.0
	for x: float in v:
		t += x
	return t / float(v.size())


static func _percentile(v: PackedFloat32Array, pct: float) -> float:
	if v.is_empty():
		return INF
	var c: PackedFloat32Array = v.duplicate()
	c.sort()
	return c[clampi(int(round(pct * float(c.size() - 1))), 0, c.size() - 1)]


## Mean unsigned angle (0-90 degrees) between the ink's local direction and
## the direction of the nearest model point. Mirroring flips diagonals.
static func tangent_angle(
	ink: Array[PackedVector2Array], model: Array[PackedVector2Array]
) -> float:
	var n: int = LearnBalance.WRITE_RESAMPLE_POINTS
	var span: int = LearnBalance.ORIENT_TANGENT_SPAN
	var model_pts: PackedVector2Array = resample(model, n)
	var ink_pts: PackedVector2Array = resample(fit_to(ink, bounds(model_pts)), n)
	if ink_pts.size() < 2 * span + 1 or model_pts.size() < 2 * span + 1:
		return 0.0
	var sum: float = 0.0
	var count: int = 0
	for i in range(span, ink_pts.size() - span):
		var ti: Vector2 = ink_pts[i + span] - ink_pts[i - span]
		var best: int = span
		var best_d: float = INF
		for j in range(span, model_pts.size() - span):
			var d: float = ink_pts[i].distance_squared_to(model_pts[j])
			if d < best_d:
				best_d = d
				best = j
		var tm: Vector2 = model_pts[best + span] - model_pts[best - span]
		if ti.length() < 0.0001 or tm.length() < 0.0001:
			continue
		var c: float = absf(ti.normalized().dot(tm.normalized()))
		sum += rad_to_deg(acos(clampf(c, 0.0, 1.0)))
		count += 1
	return 0.0 if count == 0 else sum / float(count)


## The lenient judge (owner report 2026-10-03). `others` are the models of
## every other known letter. Returns accepted, mirrored, near, distance,
## nearest_other, ink_frac, limit.
static func judge(
	ink: Array[PackedVector2Array],
	model: Array[PackedVector2Array],
	others: Array,
	hint_level: int,
	orient_check: bool
) -> Dictionary:
	var all: PackedVector2Array = PackedVector2Array()
	for st: PackedVector2Array in ink:
		all.append_array(st)
	var size: float = maxf(bounds(all).size.x, bounds(all).size.y)
	var out: Dictionary = {
		"accepted": false,
		"mirrored": false,
		"near": false,
		"distance": INF,
		"nearest_other": INF,
		"ink_frac": 0.0,
		"limit": 0.0,
		"letter_sized": size >= LearnBalance.WRITE_MIN_SIZE_PX
	}
	if all.size() < 2 or not bool(out["letter_sized"]):
		return out
	var model_box: Rect2 = bounds(resample(model, LearnBalance.WRITE_RESAMPLE_POINTS))
	var model_len: float = ink_length(model)
	var ink_frac: float = (
		0.0 if model_len <= 0.0 else ink_length(fit_to(ink, model_box)) / model_len
	)
	var d: float = distance(ink, model)
	var d_other: float = INF
	for o: Variant in others:
		d_other = minf(d_other, distance(ink, o as Array[PackedVector2Array]))
	var limit: float = (
		LearnBalance.WRITE_MATCH_MAX + LearnBalance.WRITE_MATCH_LOOSEN_STEP * float(hint_level)
	)
	var enough_ink: bool = ink_frac >= LearnBalance.WRITE_MIN_INK_FRAC
	var is_mirror: bool = false
	if orient_check and enough_ink:
		var mir: Array[PackedVector2Array] = mirrored(model)
		var d_m: float = distance(ink, mir)
		if d_m <= limit:
			var a_t: float = tangent_angle(ink, model)
			var a_m: float = tangent_angle(ink, mir)
			is_mirror = (
				d - d_m >= LearnBalance.ORIENT_DIST_MARGIN
				or a_t - a_m >= LearnBalance.ORIENT_ANGLE_MARGIN_DEG
			)
	out["mirrored"] = is_mirror
	out["distance"] = d
	out["nearest_other"] = d_other
	out["ink_frac"] = ink_frac
	out["limit"] = limit
	out["near"] = d <= LearnBalance.WRITE_NEAR_MAX and ink_frac >= 0.3
	out["accepted"] = (
		enough_ink and not is_mirror and d <= limit and d < d_other + LearnBalance.WRITE_TIE_MARGIN
	)
	return out


## Single-model check, kept for the trace step and older callers:
## {accepted, distance, ink_frac, limit}.
static func check(
	ink: Array[PackedVector2Array], model: Array[PackedVector2Array], hint_level: int
) -> Dictionary:
	var r: Dictionary = judge(ink, model, [], hint_level, false)
	return {
		"accepted": bool(r["accepted"]),
		"distance": float(r["distance"]),
		"ink_frac": float(r["ink_frac"]),
		"limit": float(r["limit"])
	}
