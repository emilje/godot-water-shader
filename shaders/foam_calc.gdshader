shader_type canvas_item;
uniform sampler2D sea_foam: repeat_enable;
uniform sampler2D noise: repeat_enable;
uniform sampler2D depth_top: repeat_disable;
uniform sampler2D depth_bottom: repeat_disable;
uniform vec2 foam_resolution;
uniform float noise_intensity_x: hint_range(-0.3, 0.3) = 0.02;
uniform float noise_intensity_z: hint_range(-0.3, 0.3) = 0.02;
uniform vec2 capture_center;
uniform float capture_coverage;
uniform float depth_coverage;
global uniform vec2 flat_point;

group_uniforms Pattern;
uniform sampler2D world_disp_noise: repeat_enable;
uniform float disp_noise_uv: hint_range(0,500) = 160.0;
uniform float smoothstep_low: hint_range(0,1) = 0.2;
uniform float smoothstep_high: hint_range(0,1) = 0.75;
uniform float amplitude_effect:hint_range(0, 1) = 0.7;

group_uniforms Warp;
uniform float warp_uv_x = 700.0;
uniform float warp_uv_y = 500.0;
uniform float warp_speed:hint_range(0, 0.01) = 0.005;
uniform vec2 warp_strength = vec2(15.0,10.0);

vec3 gerstner(vec2 pos, float angle, float amplitude, float wavelength, float speed, float steepness) {
	angle=radians(angle);
	vec2 direction = normalize(vec2(sin(-angle), cos(angle)));
	
	// Amplitude noise
    float noise_a = texture(world_disp_noise, pos/disp_noise_uv).r;
	float amplitude_noise = smoothstep(smoothstep_low, smoothstep_high,noise_a) * amplitude_effect + 1.0 - amplitude_effect;
	amplitude *= amplitude_noise;
	
	// Domain warping
	float pos_warp_x = texture(world_disp_noise, pos / warp_uv_x + vec2(1) * TIME * warp_speed).r;
	float pos_warp_y = texture(world_disp_noise, pos / warp_uv_y + vec2(1) * TIME * warp_speed).r;
	vec2 pos_warp = vec2(pos_warp_x, pos_warp_y);
	pos_warp = (pos_warp * 2.0 - 1.0) * warp_strength;
	vec2 warped_pos = pos + pos_warp;

	float frequency = TAU / wavelength;
	float phase = (TIME * speed + dot(direction, warped_pos)) * frequency;

	vec3 displacement;
	
	float noise_value = texture(noise, pos * 0.2 + TIME * direction * 0.2).r;
	displacement.y = sin(phase) * amplitude + noise_value * 0.05 - 0.05/2.0;
	displacement.xz = direction * cos(phase) * steepness;
	
	// Foam streaks
	displacement.x += noise_value * noise_intensity_x - noise_intensity_x/2.0;
	displacement.z += noise_value * noise_intensity_z - noise_intensity_z/2.0;
	
	return displacement;
}

vec3 wave(vec2 pos) {
		vec3 displacement = gerstner(pos, 0.0, 4.3, 120, 5, 0.8);
		displacement += gerstner(pos, 7.0, 4.1, 80, 8, 0.6);
		displacement += gerstner(pos, 15, 0.8, 20, 3, 0.8);
		displacement += gerstner(pos, -45, 0.4, 13, 5, 0.2);
		
		//float flat_point_distance = distance(pos, flat_point);
		//if(flat_point_distance < 100.0) {
			//float inten =  smoothstep(5,100, flat_point_distance);
			//displacement *= inten;
		//}
	
	return displacement;
}

void fragment() {
	vec2 texel = 1.0 / foam_resolution;
	vec2 sampling_distance = texel * capture_coverage;

	vec2 world_xz = capture_center + (UV - 0.5) * capture_coverage;
	vec3 disp = wave(world_xz);
	
	vec2 pos_x = world_xz + vec2(sampling_distance.x, 0.0);
	vec2 pos_z = world_xz + vec2(0.0, sampling_distance.y);
	
	vec3 disp_x = wave(pos_x);
	vec3 disp_z = wave(pos_z);
	
	vec2 wave_current = world_xz + disp.xz;
	vec2 wave_x = pos_x + disp_x.xz;
	vec2 wave_z = pos_z + disp_z.xz;
	
	vec2 dpos_x = wave_x - wave_current;
	vec2 dpos_z = wave_z - wave_current;
	
	float sa = cross(vec3(dpos_x, 0), vec3(dpos_z, 0)).z;
	float jacobian_d = sa / (sampling_distance.x * sampling_distance.y);
	
	float compression = 1.0 - smoothstep(0, 0.7, jacobian_d);
	
	float noise_v = texture(noise, world_xz / 15.0).r;
	noise_v = smoothstep(0.2,0.7, noise_v);
	noise_v *= 8.0;
	
	float foam = compression * noise_v;
	
	// Intersection foam
	vec2 disp_uv = (world_xz + disp.xz - capture_center) / depth_coverage + 0.5;
	float y_top = texture(depth_top, disp_uv).r;
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
	float i_foam = over * under;
	
	COLOR = vec4(foam, i_foam, 0, 1);
}
