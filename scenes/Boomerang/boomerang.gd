extends Node3D

@export var power := 1.0
@export var boomerang_scene: PackedScene
@export var max_pull := Vector3(0.5, 0, 0);
@export var charge_time := 1.5
@onready var camera: Camera3D = get_parent()

@export var player: CharacterBody3D

@onready var hand: Node3D = $Hand

var b: Node3D
var heldtime := 0.0
var throwing := false
var throw_dir := Vector3.ZERO

func _ready():
	spawn.call_deferred()

func spawn():
	b = boomerang_scene.instantiate()
	hand.add_child(b)            # child of the hand, so it follows and rotates with it
	b.position = Vector3.ZERO    # local position: sits exactly on the hand
	b.rotation = Vector3.ZERO
	
var velocity = Vector3.ZERO;

@export var aim_range := 40.0

var hitted = false;

var goto;

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

	if throwing:
		b.global_position += throw_dir * 20.0 * power * delta
		return

	if Input.is_action_pressed("throw"):
		heldtime += delta
		var t := clampf(heldtime / charge_time, 0.0, 1.0)
		var eased := 1.0 - (1.0 - t) * (1.0 - t)
		b.position = eased*max_pull   # LOCAL x, follows the hand's rotation
		camera.fov = 88.9+eased*40;

	elif Input.is_action_just_released("throw"):
		throw_dir = -hand.global_transform.basis.z     # capture direction at release
		b.reparent(get_tree().current_scene)           # keeps its world transform
		var hit := get_aim_target()
		var aiming_at_enemy = hit.has("collider") and hit.collider.is_in_group("enemy")
		for e in get_tree().get_nodes_in_group("enemy"):
			print("enemy at ", e.global_position, "  ray hit at ", hit.get("position"))

		if aiming_at_enemy:
			print("looking at ", hit.collider.name, " at ", hit.position)
			hitted = true
			goto = hit.position
		else:
			print("no hit ", hit)
			hitted = false;
			goto = camera.global_position + throw_dir * power * heldtime;
		throwing = true
		camera.fov = 88.9
		
		
	else:
		heldtime = 0.0
		b.position = Vector3.ZERO
