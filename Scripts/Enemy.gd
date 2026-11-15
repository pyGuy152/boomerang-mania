extends CharacterBody3D

signal damaged(amount: float, health: float)
signal knocked_back(direction: Vector3)
signal died

@export var speed := 3.0
@export var turn_speed := 8.0
@export var stop_distance := 0.1
@export var gravity := 20.0
@export var max_health := 10.0
@export var knockback_decay := 30.0

@onready var anim: AnimationPlayer = $hydranimations/AnimationPlayer

var player: Node3D
var health := 10.0
var knockback_velocity := Vector3.ZERO
var stunned := 0.0

func _ready():
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	print("player found: ", player)

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	stunned = maxf(stunned - delta, 0.0)

	if stunned > 0.0:
		# Can't chase while stunned, only the knockback moves us
		velocity.x = 0.0
		velocity.z = 0.0
	elif player:
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

	# Knockback is added on top, then fades out
	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)
	velocity.x += knockback_velocity.x
	velocity.z += knockback_velocity.z
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)
	move_and_slide()

func take_damage(amount: float):
	health -= amount
	damaged.emit(amount, health)
	if health <= 0.0:
		died.emit()
		queue_free()

func knockback(direction: Vector3, force := 12.0, stun_time := 0.3):
	direction.y = 0.0
	knockback_velocity = direction.normalized() * force   # horizontal only
	velocity.y = force * 0.3                              # one-time hop
	stunned = stun_time
	knocked_back.emit(direction)
	_stopandplay("Intimidate");

func _play(anim_name: String):
	if anim and anim.has_animation(anim_name) and (anim.current_animation == "" or anim.current_animation == anim_name):
		anim.play(anim_name)
		
func _stopandplay(anim_name: String):
	if anim and anim.current_animation != anim_name:
		anim.stop()
		anim.play(anim_name);
		
