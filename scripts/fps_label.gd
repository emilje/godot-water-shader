extends Label

var viewport_rid: RID

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	viewport_rid = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport_rid, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var gpu_ms = RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
	text = str(Engine.get_frames_per_second()) + "\n" + str(gpu_ms)
	# text = str(gpu_ms)
