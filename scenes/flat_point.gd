@tool
extends Marker3D

func _process(_delta: float) -> void:
	RenderingServer.global_shader_parameter_set("flat_point", Vector2(global_position.x,  global_position.z))
