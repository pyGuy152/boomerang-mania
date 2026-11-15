extends CharacterBody3D

@onready var walk_sound = $walk_sound
@onready var run_sound = $run_sound
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed = 5
var jump_speed = 5
var mouse_sensitivity = 0.002

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	velocity.y += -gravity * delta
	var input = Input.get_vector("left", "right", "forward", "back")
	var movement_dir = transform.basis * Vector3(input.x, 0, input.y)
	if Input.is_action_pressed("shift"):
		speed = 8.5
	else:
		speed = 5
	velocity.x = movement_dir.x * speed
	velocity.z = movement_dir.z * speed
	if velocity.x != 0 or velocity.z != 0:
		if Input.is_action_pressed("shift"):
			if not run_sound.playing:
				run_sound.play()
		else:
			if not walk_sound.playing:
				walk_sound.play()
	else:
		if run_sound.playing:
			run_sound.stop()
		if walk_sound.playing:
			walk_sound.stop()
	
	move_and_slide()
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
