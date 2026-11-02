extends SubViewport
@export var patches_node: Node3D
@export var camera: Camera3D

@onready var cull_camera: Camera3D = $Camera3D
var tiles: Array[MeshInstance3D]

func _ready() -> void:
	pass
	# var children = patches_node.find_children("*", "MeshInstance3D")
	# for tile in children:
	# 	tile.set_layer_mask_value(5, true)
	# 	tiles.append(tile)

func _process(_delta: float) -> void:
	pass
	# for tile in tiles:
	# 	tile.set_layer_mask_value(5, !is_mesh_culled(tile))


func is_mesh_culled(mesh: MeshInstance3D) -> bool:
	var aabb := mesh.global_transform * mesh.get_aabb()
	for plane in camera.get_frustum():
		var points_outside = 0
		for i in 8:
			var point := aabb.get_endpoint(i)
			var is_outside = plane.distance_to(point) > 0

			if is_outside:
				points_outside += 1
		
		if points_outside == 8:
			return true

	return false
