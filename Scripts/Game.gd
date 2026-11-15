extends Node3D

const LOSE_DISTANCE := 3.0
const ARENA_RADIUS := 30.0

@onready var player: CharacterBody3D = $Player/CharacterBody3D
@onready var enemy: CharacterBody3D = $Enemy/CharacterBody3D
@onready var boomerang: Node = $Player/CharacterBody3D/Camera3D/HandPoint

var game_state := "start"
var overlay: ColorRect
var title_label: Label
var message_label: Label
var action_button: Button
var power_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_overlay()
	_show_start_screen()

func _process(_delta: float) -> void:
	if game_state == "playing":
		power_label.text = "POWER: %.1f" % boomerang.get("aim_range")
	if game_state != "playing" or not is_instance_valid(enemy):
		return

	var horizontal_distance := Vector2(
		enemy.global_position.x - player.global_position.x,
		enemy.global_position.z - player.global_position.z
	).length()
	if horizontal_distance <= LOSE_DISTANCE:
		_show_end_screen(false)
		return

	var enemy_from_arena_center := Vector2(enemy.global_position.x, enemy.global_position.z).length()
	if enemy_from_arena_center >= ARENA_RADIUS or enemy.global_position.y < -2.0:
		_show_end_screen(true)

func _create_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.015, 0.02, 0.045, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-270, -180)
	panel.size = Vector2(540, 360)
	overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	content.add_child(title_label)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 20)
	content.add_child(message_label)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 12
	content.add_child(spacer)

	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(0, 58)
	action_button.add_theme_font_size_override("font_size", 22)
	action_button.pressed.connect(_on_action_pressed)
	content.add_child(action_button)

	power_label = Label.new()
	power_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	power_label.position = Vector2(-240, 24)
	power_label.size = Vector2(210, 48)
	power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	power_label.add_theme_font_size_override("font_size", 26)
	power_label.text = "POWER: %.1f" % boomerang.get("aim_range")
	canvas.add_child(power_label)

func _show_start_screen() -> void:
	game_state = "start"
	title_label.text = "BOOMERANG MANIA"
	message_label.text = "Knock the monster off the arena before it gets within 2 units of you."
	action_button.text = "START GAME"
	power_label.hide()
	overlay.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _show_end_screen(won: bool) -> void:
	if game_state == "won" or game_state == "lost":
		return
	game_state = "won" if won else "lost"
	title_label.text = "YOU WIN!" if won else "YOU LOSE"
	message_label.text = (
		"The monster was knocked off the arena."
		if won
		else "The monster got too close. Keep your distance!"
	)
	action_button.text = "PLAY AGAIN"
	power_label.hide()
	overlay.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _on_action_pressed() -> void:
	if game_state == "start":
		game_state = "playing"
		overlay.hide()
		power_label.show()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false
	else:
		get_tree().paused = false
		get_tree().reload_current_scene()
