@tool
extends Node3D
@export var tiles: Node3D

@onready var foam_sub_near: FoamSubviewport = $FoamSubViewport
@onready var foam_sub_far: FoamSubviewport = $FoamSubViewportFar
@onready var foam_top_depth: SubViewport = $TopDepth
@onready var foam_bottom_depth: SubViewport = $BottomDepth

@onready var top_depth_camera: Camera3D = $TopDepth/Camera3D
@onready var bottom_depth_camera: Camera3D = $BottomDepth/Camera3D

@onready var ocean_material: ShaderMaterial = $Tiles/Center_128.get_surface_override_material(0)

@export_range(1, 120) var update_hz := 40.0

@export var near_foam: bool = true:
	set(value):
		near_foam = value
		set_foam_enabled(value, foam_sub_near)

@export var far_foam: bool = true:
	set(value):
		far_foam = value
		set_foam_enabled(value, foam_sub_far)

@export var depth_foam: bool = true:
	set(value):
		depth_foam = value
		set_depth_foam_enabled()

var elapsed_s := 0.0

func can_update(delta: float) -> bool:
	elapsed_s += delta
	return elapsed_s >= 1/update_hz

func _ready() -> void:
	set_foam_enabled(near_foam, foam_sub_near)
	set_foam_enabled(far_foam, foam_sub_far)
	set_depth_foam_enabled()

func _process(delta) -> void:
	var depth_coverage := foam_sub_far.capture_coverage
	update_patches_center()

	var update := can_update(delta)

	if(update):
		var capture_center := calc_capture_center()
		ocean_material.set_shader_parameter("foam_center", capture_center)
	
		if(near_foam):
			foam_sub_near.set_depth_coverage(depth_coverage)
			foam_sub_near.update(capture_center, elapsed_s)
			if foam_sub_near.foam_texture != null:
				ocean_material.set_shader_parameter("foam_map_near", foam_sub_near.foam_texture)
				ocean_material.set_shader_parameter("foam_coverage", foam_sub_near.capture_coverage)

		if(far_foam):
			foam_sub_far.set_depth_coverage(depth_coverage)
			foam_sub_far.update(capture_center, elapsed_s)
			if foam_sub_far.foam_texture != null:
				ocean_material.set_shader_parameter("foam_map_far", foam_sub_far.foam_texture)
				ocean_material.set_shader_parameter("foam_coverage_far", foam_sub_far.capture_coverage)
		
		if(depth_foam && (near_foam || far_foam)):
			update_depth_cameras(capture_center)
			foam_top_depth.render_target_update_mode = SubViewport.UPDATE_ONCE
			foam_bottom_depth.render_target_update_mode = SubViewport.UPDATE_ONCE

		elapsed_s = 0.0

func set_foam_enabled(value: bool, subviewport: FoamSubviewport) -> void:
	if is_node_ready():
		ocean_material.set_shader_parameter("far_foam_enabled", far_foam)
		ocean_material.set_shader_parameter("near_foam_enabled", near_foam)
		var update_foam_maps: Callable = func():
			ocean_material.set_shader_parameter("foam_map_near", foam_sub_near.foam_texture)
			ocean_material.set_shader_parameter("foam_map_far", foam_sub_far.foam_texture)
			
		subviewport.set_enabled(value, update_foam_maps)

func set_depth_foam_enabled() -> void:
	if is_node_ready():
		ocean_material.set_shader_parameter("depth_foam_enabled", depth_foam)

		top_depth_camera.visible = depth_foam
		bottom_depth_camera.visible = depth_foam

func update_depth_cameras(center: Vector2) -> void:
	top_depth_camera.size = foam_sub_far.capture_coverage
	top_depth_camera.global_position.x = center.x
	top_depth_camera.global_position.z = center.y

	bottom_depth_camera.size = foam_sub_far.capture_coverage
	bottom_depth_camera.global_position.x = center.x
	bottom_depth_camera.global_position.z = center.y

	var top_mesh: QuadMesh = top_depth_camera.get_node("MeshInstance3D").mesh
	var bottom_mesh: QuadMesh = bottom_depth_camera.get_node("MeshInstance3D").mesh
	top_mesh.size = Vector2.ONE * foam_sub_far.capture_coverage
	bottom_mesh.size = top_mesh.size

func get_camera() -> Camera3D:
	var camera: Camera3D
	if Engine.is_editor_hint():
		camera = Engine.get_singleton(&"EditorInterface").get_editor_viewport_3d(0).get_camera_3d()
	else:
		camera = get_viewport().get_camera_3d()

	return camera

func calc_capture_center() -> Vector2:
	var camera := get_camera()
	if !is_instance_valid(camera):
		return Vector2.ZERO

	var meters_per_texel := float(foam_sub_near.capture_coverage) / foam_sub_near.size.x
	var intervals_in_meter := floori(1/meters_per_texel)
	var snap_dist = meters_per_texel * intervals_in_meter
	if is_nan(snap_dist):
		return Vector2.ZERO
		
	var camera_xz := Vector2(camera.global_position.x, camera.global_position.z)
	var capture_center = camera_xz.snapped(Vector2.ONE * snap_dist)

	return capture_center

func update_patches_center():
	var camera := get_camera()
	if !is_instance_valid(camera):
		return 

	var camera_xz := Vector2(camera.global_position.x, camera.global_position.z)
	var snap_distance := 40.0/4
	
	var snapped_xz = camera_xz.snapped(Vector2.ONE * snap_distance)
	tiles.global_position.x = snapped_xz.x
	tiles.global_position.z = snapped_xz.y