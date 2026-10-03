class_name CameraRig
extends Node3D
## Orbit camera (DESIGN 7.5): target, distance, pitch, yaw. The child never
## moves it; the game flies it between the hub view and the stations.

var cam: Camera3D
var target: Vector3 = Vector3.ZERO
var distance: float = 10.0
var pitch_deg: float = GameTune.CAM_PITCH_DEG
var yaw_deg: float = 0.0


func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = GameTune.CAM_FOV
	cam.near = 0.2
	cam.far = 400.0
	add_child(cam)
	_apply()


func set_pose(t: Vector3, dist: float, pitch: float, yaw: float = 0.0) -> void:
	target = t
	distance = dist
	pitch_deg = pitch
	yaw_deg = yaw
	_apply()


func fly_to(
	t: Vector3, dist: float, pitch: float, yaw: float = 0.0, sec: float = GameTune.CAM_FLY_SEC
) -> Tween:
	var from: Array = [target, distance, pitch_deg, yaw_deg]
	var tw: Tween = create_tween()
	(
		tw
		. tween_method(
			func(k: float) -> void:
				target = (from[0] as Vector3).lerp(t, k)
				distance = lerpf(float(from[1]), dist, k)
				pitch_deg = lerpf(float(from[2]), pitch, k)
				yaw_deg = lerpf(float(from[3]), yaw, k)
				_apply(),
			0.0,
			1.0,
			sec
		)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	return tw


func _apply() -> void:
	if cam == null:
		return
	var p: float = deg_to_rad(pitch_deg)
	var y: float = deg_to_rad(yaw_deg)
	var off: Vector3 = Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * distance
	cam.global_position = target + off
	cam.look_at(target, Vector3.UP)


## Where a screen point hits the horizontal plane y = h.
func ground_point(screen: Vector2, h: float) -> Vector3:
	var o: Vector3 = cam.project_ray_origin(screen)
	var d: Vector3 = cam.project_ray_normal(screen)
	if absf(d.y) < 0.0001:
		return o
	var t: float = (h - o.y) / d.y
	return o + d * t
