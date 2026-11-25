@tool
extends Node3D
class_name BuoyancyComponent

@export_tool_button("Add point", "Add") var add_point = add_b_point

var parent: RigidBody3D
var b_points: Array[Marker3D]
var ocean_settings: OceanSettings = preload("res://resources/ocean_settings.tres")
var amplitude_noise: Image
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var sphere_radius: float = 2
@export var buoyancy_multiplier: float = 2
@export var drag_multiplier: float = 1

func _ready() -> void:
	if !Engine.is_editor_hint():

		var texture := ocean_settings.amplitude_noise_texture
		amplitude_noise = texture.get_image()
		if !amplitude_noise:
			await texture.changed
			amplitude_noise = texture.get_image()

		parent = get_parent() as RigidBody3D
		if !parent:
			return

		for child in get_children():
			if child is Marker3D:
				b_points.append(child)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() || !parent:
		return

	var submerged_average = 0.0
	for point in b_points:
		var wave_height := get_wave_height(Vector2(point.global_position.x, point.global_position.z))
		var under := wave_height - point.global_position.y
		var submerged := smoothstep(-sphere_radius, sphere_radius, under)
		submerged_average += submerged / b_points.size()
		var buoyancy = parent.mass * gravity * submerged * buoyancy_multiplier / b_points.size()
		var b_force = Vector3.UP * buoyancy
		var point_offset = point.global_position - parent.global_position
		parent.apply_force(b_force, point_offset)
	
	parent.linear_damp = submerged_average * parent.linear_velocity.length() * drag_multiplier

func get_wave_height(world_xz: Vector2) -> float:
	var time := Time.get_ticks_msec()/1000.0
	var displacement = wave(world_xz, time)
	# If low/no steepness in waves, you can remove this approximation to get better performance
	world_xz -= Vector2(displacement.x, displacement.z)
	return wave(world_xz, time).y

# This should do the exact same thing the shaders do
func gerstner(pos: Vector2, angle: float, amplitude: float, wavelength: float, speed: float, steepness:float, time: float) -> Vector3:
	angle = deg_to_rad(angle)
	var direction := Vector2(-sin(angle), cos(angle)).normalized()
	var frequency := TAU / wavelength 
	var displacement: Vector3

	# Amplitude noise
	var noise_uv := pos / ocean_settings.disp_noise_uv
	var noise_a = sample_noise(noise_uv)
	var noise_a_stepped = smoothstep(ocean_settings.smoothstep_low, ocean_settings.smoothstep_high, noise_a) * ocean_settings.amplitude_effect + 1 - ocean_settings.amplitude_effect
	amplitude *= noise_a_stepped

	# Domain warping
	var offset := Vector2.ONE * time * ocean_settings.warp_speed
	var warp_noise := Vector2(
	sample_noise(pos / ocean_settings.warp_uv_x + offset),
	sample_noise(pos / ocean_settings.warp_uv_y + offset)
)
	var pos_warp := (warp_noise * 2.0 - Vector2.ONE) * ocean_settings.warp_strength
	var warped_pos := pos + pos_warp

	var phase := (time * speed + direction.dot(warped_pos)) * frequency;
	displacement.y = sin(phase) * amplitude
	displacement.x = direction.x * cos(phase) * steepness
	displacement.z = direction.y * cos(phase) * steepness

	return displacement

# This should do the exact same thing the shaders do
func wave(pos: Vector2, time: float) -> Vector3:
	var displacement: Vector3 = Vector3.ZERO
	for wave_data in ocean_settings.waves:
		if !wave_data:
			continue

		displacement += gerstner(pos, wave_data.angle, wave_data.amplitude, wave_data.wavelength, wave_data.speed, wave_data.steepness, time)

	return displacement

# This wraps the noise texture like repeat_enable in the shaders
func sample_noise(uv: Vector2) -> float:
	var size := amplitude_noise.get_size()
	var pixel := Vector2i(floori(uv.x * size.x), floori(uv.y * size.y))

	pixel.x = wrapi(pixel.x, 0, size.x)
	pixel.y = wrapi(pixel.y, 0, size.y)

	return amplitude_noise.get_pixelv(pixel).r

func add_b_point() -> void:
	if Engine.is_editor_hint():
		var point = Marker3D.new()
		point.name = "Point_" + str(get_child_count() + 1)
		add_child(point)
		point.owner = get_tree().edited_scene_root
		Engine.get_singleton(&"EditorInterface").mark_scene_as_unsaved()