@tool
extends Node3D

@onready var ocean: MeshInstance3D = $MeshInstance3D

@onready var current: SubViewport = $FoamSubViewport
@onready var history_a: SubViewport = $HistoryA
@onready var history_b: SubViewport = $HistoryB

@onready var material_a: ShaderMaterial = $HistoryA/ColorRect.material
@onready var material_b: ShaderMaterial = $HistoryB/ColorRect.material

var ocean_material: ShaderMaterial
var write_a = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	ocean_material = ocean.get_surface_override_material(0)

	material_a.set_shader_parameter("delta", delta)
	material_b.set_shader_parameter("delta", delta)

	if(write_a):
		history_a.render_target_update_mode = SubViewport.UPDATE_ONCE
		history_b.render_target_update_mode = SubViewport.UPDATE_DISABLED

		ocean_material.set_shader_parameter("foam_map", history_a.get_texture())
	else:
		history_b.render_target_update_mode = SubViewport.UPDATE_ONCE
		history_a.render_target_update_mode = SubViewport.UPDATE_DISABLED

		ocean_material.set_shader_parameter("foam_map", history_b.get_texture())

	write_a = !write_a