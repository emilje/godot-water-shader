@tool
extends Resource
class_name OceanSettings

var Waves: Dictionary[String, PackedFloat32Array] = {
	"wave_angles": PackedFloat32Array(),
	"wave_amplitudes": PackedFloat32Array(),
	"wave_wavelengths": PackedFloat32Array(),
	"wave_speeds": PackedFloat32Array(),
	"wave_steepnesses": PackedFloat32Array()
}
var MAX_WAVES: int = 12
@export var waves: Array[WaveData]:
	set(value):
		if(value.size() > MAX_WAVES):
			return

		for wave in waves:
			if !wave:
				continue
			if wave.is_connected(changed.get_name(), emit_changed):
				wave.changed.disconnect(emit_changed)

		waves = value
		
		for wave in waves:
			if !wave:
				continue
			wave.changed.connect(emit_changed)
		
		emit_changed()

@export_group("Pattern")
@export var amplitude_noise_texture: NoiseTexture2D = preload("res://textures/amplitude_noise_texture.tres"):
	set(value):
		amplitude_noise_texture = value
		emit_changed()
@export var disp_noise_uv: float = 410:
	set(value):
		disp_noise_uv = value
		emit_changed()
@export var smoothstep_low: float = 0.2:
	set(value):
		smoothstep_low = value
		emit_changed()
@export var smoothstep_high: float = 1:
	set(value):
		smoothstep_high = value
		emit_changed()
@export var amplitude_effect: float = 0.8:
	set(value):
		amplitude_effect = value
		emit_changed()

@export_group("Warp")
@export var warp_uv_x: float = 40:
	set(value):
		warp_uv_x = value
		emit_changed()
@export var warp_uv_y: float = 500:
	set(value):
		warp_uv_y = value
		emit_changed()
@export var warp_speed: float = 0.002:
	set(value):
		warp_speed = value
		emit_changed()
@export var warp_strength: Vector2 = Vector2(4,20):
	set(value):
		warp_strength = value
		emit_changed()

func get_wave_data() -> Dictionary[String, PackedFloat32Array]:
	for key in Waves:
		Waves[key].clear()
		
	for wave in waves:
		if !wave:
			continue
			
		Waves.wave_angles.append(wave.angle)
		Waves.wave_amplitudes.append(wave.amplitude)
		Waves.wave_wavelengths.append(wave.wavelength)
		Waves.wave_speeds.append(wave.speed)
		Waves.wave_steepnesses.append(wave.steepness)
	
	return Waves

func set_shader_params(material: ShaderMaterial):
	var wave_data = get_wave_data()
	var count: int = wave_data.wave_angles.size()
	for key in wave_data:
		material.set_shader_parameter(key, wave_data[key])

	# Wave data
	material.set_shader_parameter("wave_count", mini(count, MAX_WAVES))

	# Pattern
	material.set_shader_parameter("disp_noise_uv", disp_noise_uv)
	material.set_shader_parameter("smoothstep_low", smoothstep_low)
	material.set_shader_parameter("smoothstep_high", smoothstep_high)
	material.set_shader_parameter("amplitude_effect", amplitude_effect)
	material.set_shader_parameter("amplitude_noise_texture", amplitude_noise_texture)
	
	# Warp
	material.set_shader_parameter("warp_uv_x", warp_uv_x)
	material.set_shader_parameter("warp_uv_y", warp_uv_y)
	material.set_shader_parameter("warp_speed", warp_speed)
	material.set_shader_parameter("warp_strength", warp_strength)