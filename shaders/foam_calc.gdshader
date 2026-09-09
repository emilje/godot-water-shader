shader_type canvas_item;
uniform sampler2D displacement_map;
uniform sampler2D sea_foam: repeat_enable;
uniform sampler2D noise;
uniform sampler2D depth_top;
uniform sampler2D depth_bottom;

vec3 get_displacement(vec2 uv) {
	return texture(displacement_map, uv).rgb;
}

void fragment() {
	vec2 texel = 1.0 / vec2(textureSize(displacement_map, 0));
	vec2 sampling_distance = texel * 10.0;
	
	vec2 pos = (UV-0.5)*10.0;
	vec3 disp = get_displacement(UV);
	vec2 wave_current = pos + disp.xz;
	vec2 wave_r = pos + vec2(sampling_distance.x, 0) + get_displacement(UV + vec2(texel.x, 0)).xz;
	vec2 wave_b = pos + vec2(0, sampling_distance.y) + get_displacement(UV + vec2(0, texel.y)).xz;
	
	vec2 dpos_x = wave_r - wave_current;
	vec2 dpos_z = wave_b - wave_current;
	
	float sa = cross(vec3(dpos_x, 0), vec3(dpos_z, 0)).z;
	float jacobian_d = sa / (sampling_distance.x * sampling_distance.y);
	
	float compression = 1.0 - smoothstep(0, 0.7, jacobian_d);
	float foam_hf = texture(sea_foam, UV* 24.0).r;
	float foam_lf = texture(sea_foam, UV* 8.0).r;
	
	float mixed_foam = mix(foam_lf, foam_hf, compression);
	mixed_foam = smoothstep(0.4, 1, mixed_foam);
	
	float noise_v = texture(noise, UV).r;
	noise_v = smoothstep(0.2,0.7, noise_v);
	noise_v *= 8.0;
	
	float foam = clamp(compression * mixed_foam * noise_v, 0, 1);
	
	// Intersection foam
	vec2 disp_uv = UV + disp.xz /10.0;
	float y_top = texture(depth_top, disp_uv ).r;
	float y_bottom = texture(depth_bottom, vec2(disp_uv.x, 1.0 - disp_uv.y)).r;
	float y_water = disp.y;
	
	// Reference i_depth_shader comments
	#if(CURRENT_RENDERER == RENDERER_COMPATIBILITY)
	y_top = mix(-10, 10, y_top);
	y_bottom = mix(-10, 10, y_bottom);
	#endif
	
	float over = y_top - y_water;
	float under = y_water - y_bottom;
	over = smoothstep(0,0.15, over);
	under = smoothstep(0,0.15, under);
	
	float i_noise_lf = texture(sea_foam, UV * 2.0).r;
	float i_noise_hf = texture(sea_foam, UV * 16.0).r;
	float i_foam_noise = i_noise_lf * i_noise_hf;
	i_foam_noise = smoothstep(0.3,1, i_foam_noise);
	
	float i_foam = over * under * i_foam_noise;
	
	COLOR = vec4(foam, i_foam, 0, 1);
}
