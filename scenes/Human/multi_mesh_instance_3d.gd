extends MultiMeshInstance3D

@export var grass_scene: PackedScene
@export var count := 2000
@export var area_size := Vector2(60, 60)
var shader_mat = preload("res://Material/grass.tres")

func _ready():
	var grass = grass_scene.instantiate()

	var mesh_instance = grass
	var grass_mesh = mesh_instance.mesh

	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = grass_mesh
	multimesh.instance_count = count

	for i in range(count):
		var x = randf_range(-area_size.x / 2, area_size.x / 2)
		var z = randf_range(-area_size.y / 2, area_size.y / 2);
		
		if x*x + z*z > 900:
			continue;

		var scale_factor = pow(randf_range(0.2, 1), 2)
		var rotation = randf() * TAU

		var basis = Basis(Vector3.UP, rotation).scaled(
			Vector3(0.05, 0.2, 0.05) * scale_factor
		)

		multimesh.set_instance_transform(
			i,
			Transform3D(basis, Vector3(x, 0, z))
		)
		material_override = shader_mat;

	grass.free()
