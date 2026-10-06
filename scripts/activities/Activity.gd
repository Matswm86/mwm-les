class_name Activity
extends Node3D
## Base for the three stations on the island. Main flies the camera to
## camera_pose(), calls begin(), awaits run() and then calls end(). Touches
## arrive through touch(); the speaker button calls replay(). All sound goes
## through the Voice autoload (owner recordings only).

signal step(name: String)  # a named moment, for the screenshot bot and the test

var main: MainScene
var active: bool = false  # the child may act now
var _seq: int = 0  # bumped by every new action; older awaits then stop


func activity_id() -> String:
	return ""


## The hub line that sends the child here.
func hub_line() -> String:
	return ""


## Camera pose for this station: target, distance, pitch, yaw.
func camera_pose() -> Dictionary:
	return {}


func begin() -> void:
	Voice.reset_chime()


## The whole station, start to finish.
func run() -> void:
	pass


func end() -> void:
	active = false
	main.hud.ghost.stop()


func touch(_event: InputEvent) -> void:
	pass


## True when a press at `pos` is meant for this station (a stone under the
## finger), so a tap near Pip there does not count as a tap on Pip.
func claims_touch(_pos: Vector2) -> bool:
	return false


## The speaker button: hear the sound the child is looking for again.
func replay() -> void:
	pass


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


## Says `ids` and waits until the sequence is over (plus `extra` seconds).
func say_wait(ids: Array, extra: float = 0.15) -> void:
	await Voice.say_wait(ids, extra)


func _mark(name: String) -> void:
	step.emit(name)
