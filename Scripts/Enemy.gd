extends CharacterBody3D

@export var speed := 3.0
@export var turn_speed := 8.0
@export var stop_distance := 0.1
@export var gravity := 20.0

@onready var anim: AnimationPlayer = $hydranimations/AnimationPlayer

var player: Node3D

func _ready():
	player = get_tree().get_first_node_in_group("player")
	print("player found: ", player)

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	if player:
		var to_player = player.global_position - global_position
		to_player.y = 0.0
		var dist = to_player.length()

		if dist > stop_distance:
			var dir = to_player.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed

			# Turn smoothly toward the player
			var target_angle = atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)

			_play("Walk")
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			_play("Intimidate")
			

	move_and_slide()

func _play(anim_name: String):
	if anim and anim.has_animation(anim_name) and anim.current_animation != anim_name:
		anim.play(anim_name)
