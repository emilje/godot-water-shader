shader_type spatial;
uniform float delay = 0.0;

void vertex() {
	float time = max(TIME - delay, 0.0);
	VERTEX.y += 4.0 * sin(time * 1.4);
	VERTEX.x += 2.4 * sin(time*1.7);
	VERTEX.z += 2.4 * cos(time*1.7);
}

void fragment() {
	ALBEDO = vec3(0.7);
}
