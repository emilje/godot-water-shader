shader_type spatial;
render_mode depth_draw_always;
uniform vec3 color: source_color;
uniform float sampling_distance = 0.01;
uniform sampler2D displacement_map: repeat_disable;
uniform sampler2D foam_map: repeat_disable;
uniform sampler2D depth_texture: hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable;
uniform float absorption_strength = 0.5;
uniform vec3 color_absorption = vec3(1.3, 0.4, 0.6);
uniform sampler2D i_noise_texture;

float get_through_water(vec2 uv, float depth, mat4 i_proj_mat, float vertex_z) {
	#if(CURRENT_RENDERER == RENDERER_COMPATIBILITY)
		vec3 ndc = vec3(uv, depth) * 2.0 - 1.0;
	#else
		vec3 ndc = vec3(uv  * 2.0 - 1.0, depth);
	#endif
	
	vec4 view_pos = i_proj_mat * vec4(ndc, 1);
	float through_water = -(view_pos/view_pos.w).z + vertex_z;
	
	return through_water;
}

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
	vec3 mixed_color = mix(color, vec3(0,0.08,0.02), h_blend);
	vec4 foam = texture(foam_map, UV);
	
	mixed_color = mix(mixed_color, vec3(0.4,0.7,0.6), foam.r);
	mixed_color = mix(mixed_color, vec3(0.4,0.7,0.6), foam.g);
	
	//Refraction
	vec3 normal = normalize(NORMAL);
	vec2 dist_strength = vec2(0.025, 0.01) * 1.25;
	vec2 planned_distortion = vec2(normal.x, -normal.y) * dist_strength;
	float distance_factor = clamp(4.0 / -VERTEX.z, 0, 1);

	vec2 d_uv = SCREEN_UV + planned_distortion * distance_factor;
	float d_depth = texture(depth_texture, d_uv).r;
	
	float through_water = get_through_water(d_uv, d_depth, INV_PROJECTION_MATRIX, VERTEX.z);
	float blend = smoothstep(0,0.5, through_water) * 0.8;
	
	d_uv = SCREEN_UV + planned_distortion * distance_factor * blend;
	d_depth = texture(depth_texture, d_uv).r;
	through_water = max(get_through_water(d_uv, d_depth, INV_PROJECTION_MATRIX, VERTEX.z), 0.0);
	
	if(d_depth > 0.0) {
		vec3 tex = texture(screen_texture, d_uv).rgb;
		
		//Depth fade
		tex *= exp(-through_water * absorption_strength * color_absorption);
		EMISSION = tex;
	}
	
	//Intersection
	float i_noise = texture(i_noise_texture, UV * 20.0 + TIME * 0.03).r;
	float i_width = 0.05 + sin(TIME * 0.5) * 0.02 + i_noise * 0.04;
	if(through_water > 0.0 && through_water < i_width) {
		float fade_in = smoothstep(0, 0.1 * i_width, through_water);
		float fade_out = 1.0 - smoothstep(0.8 * i_width, i_width, through_water);
		
		mixed_color = mix(mixed_color, vec3(0.4,0.7,0.6), fade_in * fade_out);
	}
	
	ALBEDO = mixed_color;
	RIM = 2.0;
	ROUGHNESS = 0.01;
}
