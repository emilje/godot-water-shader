shader_type spatial;
uniform vec3 color: source_color;
uniform float sampling_distance = 0.01;
uniform sampler2D displacement_map: repeat_disable;
uniform sampler2D foam_map: repeat_disable;

vec3 get_displacement(vec2 uv) {
	return texture(displacement_map, uv).rgb;
}

void vertex() {
	vec3 pos = VERTEX.xyz;
	VERTEX += get_displacement(pos.xz/10.0 + 0.5);
	
	vec3 fwd_pos = pos + vec3(0,0,-1) * sampling_distance;
	vec3 left_pos = pos + vec3(-1,0,0) * sampling_distance;
	
	vec3 wave_fwd = fwd_pos + get_displacement(fwd_pos.xz/10.0 + 0.5);
	vec3 wave_left = left_pos + get_displacement(left_pos.xz/10.0 + 0.5);
	
	vec3 fwd_vec = wave_fwd - VERTEX;
	vec3 left_vec = wave_left - VERTEX;
	
	NORMAL = normalize(cross(fwd_vec, left_vec));
}


void fragment() {
	vec4 world_pos = INV_VIEW_MATRIX * vec4(VERTEX, 1);
	float h_blend = smoothstep(-0.7, 1, world_pos.y);
	vec3 mixed_color = mix(color, vec3(0,0.08,0.04), h_blend);
	vec4 foam = texture(foam_map, UV);
	
	mixed_color = mix(mixed_color, vec3(0.4,0.7,0.6), foam.r);
	mixed_color = mix(mixed_color, vec3(0.4,0.7,0.6), foam.g);
	
	ALBEDO = mixed_color;
	RIM = 2.0;
	ROUGHNESS = 0.01;
	EMISSION = vec3(1,0.5,0.2) * foam.g * 15.0;
}
