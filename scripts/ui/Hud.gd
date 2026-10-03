class_name Hud
extends CanvasLayer
## Icon-only HUD (DESIGN 5): voice replay top-left, home top-right during
## activities; a small, low-contrast parent button top-left on the hub.

signal replay_pressed
signal home_pressed
signal parent_pressed

var replay_btn: RoundButton
var home_btn: RoundButton
var parent_btn: RoundButton
var root: Control


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var m: float = GameTune.SAFE_MARGIN_PX
	replay_btn = RoundButton.new().setup(
		GameTune.BTN_SECONDARY_PX, GameTune.SEA_BTN, RoundButton.Icon.SPEAKER
	)
	replay_btn.position = Vector2(m, m * 0.6)
	replay_btn.pressed.connect(func() -> void: replay_pressed.emit())
	root.add_child(replay_btn)
	home_btn = RoundButton.new().setup(
		GameTune.BTN_SECONDARY_PX, GameTune.SEA_BTN, RoundButton.Icon.HOUSE
	)
	Hud.place_top_right(home_btn, m * 0.6)
	home_btn.pressed.connect(func() -> void: home_pressed.emit())
	root.add_child(home_btn)
	parent_btn = RoundButton.new().setup(
		GameTune.BTN_MIN_PX, Color(1, 1, 1, 0.35), RoundButton.Icon.PARENT
	)
	parent_btn.icon_color = Color(GameTune.INK, 0.55)
	parent_btn.position = Vector2(m * 0.5, m * 0.5)
	parent_btn.modulate = Color(1, 1, 1, 0.6)
	parent_btn.pressed.connect(func() -> void: parent_pressed.emit())
	root.add_child(parent_btn)
	show_hub()


## Pin a button to the top-right corner (anchors + offsets, so it follows
## wide phones with aspect "expand").
static func place_top_right(c: Control, y: float) -> void:
	var w: float = c.size.x
	c.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	c.offset_left = -GameTune.SAFE_MARGIN_PX - w
	c.offset_right = -GameTune.SAFE_MARGIN_PX
	c.offset_top = y
	c.offset_bottom = y + c.size.y


func show_hub() -> void:
	replay_btn.visible = false
	home_btn.visible = false
	parent_btn.visible = true


func show_activity() -> void:
	replay_btn.visible = true
	home_btn.visible = true
	parent_btn.visible = false


func hide_all() -> void:
	replay_btn.visible = false
	home_btn.visible = false
	parent_btn.visible = false


func add_overlay(c: Control) -> void:
	root.add_child(c)
