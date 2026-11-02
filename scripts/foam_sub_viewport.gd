@tool
class_name FoamSubviewport
extends SubViewport

@export_range(0, 500) var capture_coverage: int = 10
@export var history_a: SubViewport
@export var history_b: SubViewport
@export_range(0, 5) var decay_rate: float = 0.2
@export_range(0, 5) var erosion_multiplier: float = 3.0
@export_range(1, 120) var update_hz := 60.0

@onready var m_foam: ShaderMaterial = $ColorRect.material

var foam_resolution := Vector2i.ZERO
var m_history_a: ShaderMaterial
var m_history_b: ShaderMaterial
var write_a := true
var history_initialized := false
var foam_texture: Texture2D
var previous_center := Vector2.ZERO
var capture_center := Vector2.ZERO
var elapsed_s := 0.0

func can_update(delta: float):
	elapsed_s += delta
	return elapsed_s >= 1/update_hz

func update(center: Vector2) -> void:
	if !history_initialized:
		if !init_history():
			return

	update_history_resolution()
	update_capture_center(center)

	var material = m_history_a if write_a else m_history_b
	var target = history_a if write_a else history_b
	var previous = history_b if write_a else history_a

	material.set_shader_parameter("delta", elapsed_s)
	material.set_shader_parameter("decay_rate", decay_rate)
	material.set_shader_parameter("erosion_multiplier", erosion_multiplier)

	render_target_update_mode = SubViewport.UPDATE_ONCE
	target.render_target_update_mode = SubViewport.UPDATE_ONCE
	previous.render_target_update_mode = SubViewport.UPDATE_DISABLED
	foam_texture = target.get_texture()

	write_a = !write_a
	elapsed_s = 0

func update_capture_center(center: Vector2) -> void:
	capture_center = center
	update_history_offset(capture_center)

	m_foam.set_shader_parameter("capture_center", capture_center)
	m_foam.set_shader_parameter("capture_coverage", capture_coverage)
	m_history_a.set_shader_parameter("capture_center", capture_center)
	m_history_a.set_shader_parameter("capture_coverage", capture_coverage)
	m_history_b.set_shader_parameter("capture_center", capture_center)
	m_history_b.set_shader_parameter("capture_coverage", capture_coverage)

func update_history_offset(center: Vector2) -> void:
	if !history_initialized:
		if !init_history():
			return

	var offset := Vector2.ZERO
	offset = (center - previous_center) / capture_coverage

	m_history_a.set_shader_parameter("foam_history_offset", offset)
	m_history_b.set_shader_parameter("foam_history_offset", offset)

	previous_center = center

func update_history_resolution() -> void:
	if size == foam_resolution || !is_instance_valid(history_a) || !is_instance_valid(history_b):
		return

	foam_resolution = size
	history_a.size = size
	history_b.size = size

	m_foam.set_shader_parameter("foam_resolution", Vector2(size))

func init_history() -> bool:
	if !is_instance_valid(history_a) || !is_instance_valid(history_b):
		return false

	m_history_a = history_a.get_node("ColorRect").material
	m_history_b = history_b.get_node("ColorRect").material

	m_history_a.set_shader_parameter("current_foam", get_texture())
	m_history_b.set_shader_parameter("current_foam", get_texture())
	m_history_a.set_shader_parameter("history_foam", history_b.get_texture())
	m_history_b.set_shader_parameter("history_foam", history_a.get_texture())

	history_a.render_target_update_mode = SubViewport.UPDATE_DISABLED
	history_b.render_target_update_mode = SubViewport.UPDATE_DISABLED
	history_initialized = true
	return true

func set_enabled(enabled: bool, updateFoamMaps: Callable) -> void:
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	history_a.render_target_update_mode = SubViewport.UPDATE_DISABLED
	history_b.render_target_update_mode = SubViewport.UPDATE_DISABLED
	elapsed_s = 0

	if(!enabled):
		var image = Image.create(1,1,false, Image.FORMAT_R8)
		image.fill(Color.BLACK)
		foam_texture = ImageTexture.create_from_image(image)
		updateFoamMaps.call()

func set_depth_coverage(depth_coverage: float) -> void:
	m_foam.set_shader_parameter("depth_coverage", depth_coverage)