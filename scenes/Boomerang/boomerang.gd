extends Node3D

@export var power := 1.0
@export var boomerang_scene: PackedScene
@export var max_pull := Vector3(0.5, 0, 0);
@export var charge_time := 1.5
@onready var camera: Camera3D = get_parent()

@export var player: CharacterBody3D

@onready var hand: Node3D = $Hand

@export var enemy: CharacterBody3D

@export var shake_decay := 0.6        # how fast the shake fades
var shake := 0.0

func add_shake(amount: float):
	shake = maxf(shake, amount)

var noise := FastNoiseLite.new()
var shake_time := 0.0

func _process(delta):
	aim_range += aim_range_growth * delta
	shake = move_toward(shake, 0.0, shake_decay * delta)
	shake_time += delta
	camera.h_offset = noise.get_noise_2d(shake_time, 0.0) * shake * 20.0
	camera.v_offset = noise.get_noise_2d(0.0, shake_time) * shake * 20.0

var b: Node3D
var heldtime := 0.0
var throwing := false
var throw_dir := Vector3.ZERO

@onready var MouseClickSound = $MouseClickSound;

func _ready():
	spawn.call_deferred()

func spawn():
	b = boomerang_scene.instantiate()
	hand.add_child(b)            # child of the hand, so it follows and rotates with it
	b.position = Vector3.ZERO    # local position: sits exactly on the hand
	b.rotation = Vector3.ZERO
	
var velocity = Vector3.ZERO;

@export var aim_range := 10.0
@export var aim_range_growth := 0.5

var hitted = false;

var goto;


@export var out_speed := 30.0
@export var return_speed := 35.0
var returning := false

func get_aim_target() -> Dictionary:
	var cam := get_viewport().get_camera_3d()
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * aim_range

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.exclude = [player.get_rid()]   # assign the array, don't append

	return get_world_3d().direct_space_state.intersect_ray(query)

func _physics_process(delta):
	if b == null:
		return

# in _physics_process
	if throwing:
		var target = hand.global_position if returning else goto
		var speed := return_speed if returning else out_speed

		b.global_position = b.global_position.move_toward(target, speed * power * delta)
		

		if b.global_position.distance_to(target) < 0.5:
			if not returning:
				returning = true;
				if hitted:
					var dir = enemy.global_position - player.global_position
					enemy.knockback(dir, heldtime * aim_range * 2)
				heldtime = 0.0
			else:
				b.reparent(hand, false)   # false = don't keep the world transform
				b.position = Vector3.ZERO
				b.rotation = Vector3.ZERO
				throwing = false
				returning = false         # reset, or the next throw flies straight to the hand
		return

	if Input.is_action_pressed("throw"):
		heldtime += delta
		var t := clampf(heldtime / charge_time, 0.0, 1.0)
		var eased := 1.0 - (1.0 - t) * (1.0 - t)
		b.position = eased*max_pull   # LOCAL x, follows the hand's rotation
		camera.fov = 88.9 + eased * 30
		b.position = eased * max_pull
		if t >= 1.0:
			add_shake(0.03)
		

	elif Input.is_action_just_released("throw"):
		var hit := get_aim_target()
		MouseClickSound.play();

		var c = hit.get("collider")
		var aiming_at_enemy = c != null and (
			c.is_in_group("enemy")
			or (c.get_parent() != null and c.get_parent().is_in_group("enemy"))
			or (c.get_parent() != null and c.get_parent().name.begins_with("Enemy"))
		)
		
		if aiming_at_enemy:
			hitted = true
			print("HIT")
			goto = hit.position;
		else:
			hitted = false
			goto = hit.get("position", camera.global_position - camera.global_transform.basis.z * aim_range)

		throw_dir = (goto - b.global_position).normalized()
		b.reparent(get_tree().current_scene)
		throwing = true
		camera.fov = 88.9
		
		
	else:
		heldtime = 0.0
		b.position = Vector3.ZERO
