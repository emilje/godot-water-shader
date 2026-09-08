shader_type spatial;

void vertex() {
	VERTEX.x += 4.0 * sin(TIME*4.0);
	VERTEX.z += 2.0 * sin(TIME*8.0);
}
