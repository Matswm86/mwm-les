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


## Returns {accepted, distance, ink_frac}. Model box height is the letter height (1.0).
static func check(
	ink: Array[PackedVector2Array], model: Array[PackedVector2Array], hint_level: int
) -> Dictionary:
	var n: int = LearnBalance.WRITE_RESAMPLE_POINTS
	var model_pts: PackedVector2Array = resample(model, n)
	var model_box: Rect2 = bounds(model_pts)
	var fitted: Array[PackedVector2Array] = fit_to(ink, model_box)
	var ink_pts: PackedVector2Array = resample(fitted, n)
	var dist: float = 0.5 * (mean_nearest(ink_pts, model_pts) + mean_nearest(model_pts, ink_pts))
	var model_len: float = ink_length(model)
	var ink_frac: float = 0.0 if model_len <= 0.0 else ink_length(fitted) / model_len
	var limit: float = (
		LearnBalance.WRITE_MATCH_MAX + LearnBalance.WRITE_MATCH_LOOSEN_STEP * float(hint_level)
	)
	var ok: bool = dist <= limit and ink_frac >= LearnBalance.WRITE_MIN_INK_FRAC
	return {"accepted": ok, "distance": dist, "ink_frac": ink_frac, "limit": limit}
