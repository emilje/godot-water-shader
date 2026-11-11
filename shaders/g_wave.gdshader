shader_type spatial;
render_mode depth_draw_always, world_vertex_coords;
uniform vec3 color: source_color;
uniform vec3 crest_color: source_color;

uniform float sampling_distance = 0.01;
uniform sampler2D foam_map_near: repeat_disable;
uniform sampler2D foam_map_far: repeat_disable;
uniform sampler2D depth_texture: hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable;
uniform float absorption_strength = 0.5;
uniform vec3 color_absorption = vec3(1.3, 0.4, 0.6);
uniform sampler2D i_noise_texture;
uniform sampler2D noise: repeat_enable, filter_linear_mipmap;
uniform float noise_intensity = 0.05;
uniform sampler2D noise_normal_texture: hint_normal, repeat_enable, filter_linear_mipmap;

uniform vec2 foam_center;
uniform float foam_coverage;
uniform float foam_coverage_far;
uniform sampler2D sea_foam: repeat_enable;
varying float camera_dist;
varying vec2 foam_uv_near;
varying vec2 foam_uv_far;
varying vec2 world_xz;
uniform vec3 horizon_color: source_color;
varying float h_dist;
uniform bool far_foam_enabled = true;
uniform bool near_foam_enabled = true;
uniform bool depth_foam_enabled = true;
global uniform vec2 flat_point;

group_uniforms Pattern;
uniform sampler2D world_disp_noise: repeat_enable;
uniform float disp_noise_uv: hint_range(0,500) = 160.0;
uniform float smoothstep_low: hint_range(0,1) = 0.2;
uniform float smoothstep_high: hint_range(0,1) = 0.75;
uniform float amplitude_effect:hint_range(0, 1) = 0.7;

group_uniforms Warp;
uniform float warp_uv_x = 40.0;
uniform float warp_uv_y = 500.0;
uniform float warp_speed:hint_range(0, 0.01) = 0.005;
uniform vec2 warp_strength = vec2(15.0,10.0);

vec3 gerstner(vec2 pos, float angle, float amplitude, float wavelength, float speed, float steepness,
 inout int noise_to_sample) {
	angle=radians(angle);
	vec2 direction = normalize(vec2(sin(-angle), cos(angle)));
	
	// Amplitude noise
    float noise_a = texture(world_disp_noise, pos/disp_noise_uv).r;
	float amplitude_noise = smoothstep(smoothstep_low, smoothstep_high,noise_a) * amplitude_effect + 1.0 - amplitude_effect;
	amplitude *= amplitude_noise;
	
	// Domain warping
	float pos_warp_x = texture(world_disp_noise, pos / warp_uv_x + vec2(TIME * warp_speed)).r;
	float pos_warp_y = texture(world_disp_noise, pos / warp_uv_y + vec2(TIME * warp_speed)).r;
	
	vec2 pos_warp = vec2(pos_warp_x, pos_warp_y);
	pos_warp = (pos_warp * 2.0 - 1.0) * warp_strength;
	vec2 warped_pos = pos + pos_warp;

	float frequency = TAU / wavelength;
	float phase = (TIME * speed + dot(direction, warped_pos)) * frequency;
	vec3 displacement;
	displacement.y = sin(phase) * amplitude;
	displacement.xz = direction * cos(phase) * steepness;
	
	if(noise_to_sample > 0){
		float noise_value = texture(noise, pos * 0.2 + TIME * direction * 0.2).r;
		displacement.y += noise_value * noise_intensity - noise_intensity/2.0;
		noise_to_sample--;
	}
	
	return displacement;
}

vec3 wave(vec2 pos, int noise_samples) {
	int noise_num = noise_samples;
	vec3 displacement = gerstner(pos, 0.0, 4.3, 120, 5, 0.8, noise_num);
		displacement += gerstner(pos, -10.0, 4.1, 80, 8, 0.6, noise_num);
		displacement += gerstner(pos, 15, 0.8, 20, 3, 0.8, noise_num);
		displacement += gerstner(pos, -45, 0.3, 13, 5, 0.2, noise_num);
		
		float flat_point_distance = distance(pos, flat_point);
		if(flat_point_distance < 100.0) {
			float inten =  smoothstep(5,100, flat_point_distance);
			displacement *= inten;
		}
	
	return displacement;
}

// Maybe not worth the hassle to keep derivatives? Performance is better tho... 
//void gerstner_normal(vec2 pos, float angle, float amplitude, float frequency, float speed, float steepness,
//inout vec3 tangent_x, inout vec3 tangent_z, bool sample_noise) {
	//angle=radians(angle);
	//vec2 direction = normalize(vec2(sin(-angle), cos(angle)));
    //float phase = TIME * speed + dot(direction, pos) * frequency;
//
    //// pos.x derivatives
    //float phase_derivative_x = direction.x * frequency;
    //float tangent_x_x = direction.x * -sin(phase) * phase_derivative_x * steepness;
    //float tangent_x_y = cos(phase) * phase_derivative_x * amplitude;
    //float tangent_x_z = direction.y * steepness * -sin(phase) * phase_derivative_x;
    //tangent_x += vec3(tangent_x_x, tangent_x_y, tangent_x_z);
//
    //// pos.y derivatives
    //float phase_derivative_z = direction.y * frequency;
    //float tangent_z_x = direction.x * steepness * -sin(phase) * phase_derivative_z;
    //float tangent_z_y = cos(phase) * phase_derivative_z * amplitude;
    //float tangent_z_z = direction.y * steepness * -sin(phase) * phase_derivative_z;
    //tangent_z += vec3(tangent_z_x, tangent_z_y, tangent_z_z);
//
    //// noise derivatives
	//if (sample_noise) {
    	//vec2 noise_uv = pos * 0.2 + TIME * direction * 0.2;
	    //vec3 noise_normal = texture(noise_normal_texture, noise_uv).rgb * 2.0 - 1.0;
	    //float noise_scale = 0.64;
	    //vec2 slope = vec2(-noise_normal.x, noise_normal.y) * noise_scale;
//
	    //tangent_x.y += slope.x;
	    //tangent_z.y += slope.y;
	//}
//}
//
//vec3 wave_normal(vec2 pos) {
    //vec3 tangent_x = vec3(1.0, 0.0, 0.0);
    //vec3 tangent_z = vec3(0.0, 0.0, 1.0);
//
    //gerstner_normal(pos, 0.0, 0.7, 0.2, 1.0, 1.2, tangent_x, tangent_z, true);
    //gerstner_normal(pos, 25.0, 0.7, 0.3, 1.2, 0.8, tangent_x, tangent_z, true);
    //gerstner_normal(pos, -15, 0.2, 0.6, 1.4, 0.4, tangent_x, tangent_z, true);
    //gerstner_normal(pos, -50, 0.1, 0.6, 1.8, 0.2, tangent_x, tangent_z, true);
    //gerstner_normal(pos, 8.0, 0.1, 1.4, 2.0, 0.1, tangent_x, tangent_z, true);
//
    //return normalize(cross(tangent_z, tangent_x));
//}

vec2 create_mixed_foam(float foam_old, float foam_fresh, vec2 foam) {
	float mixed_foam_j = mix(foam_old, foam_fresh, foam.x);
	mixed_foam_j = smoothstep(0.4, 1, mixed_foam_j);
	foam.x = clamp(foam.x * mixed_foam_j, 0, 1);
	
	foam.y *= mix(foam_old, foam_fresh, foam.y);
	foam.y = smoothstep(0.4, 1, foam.y);
	
	return foam;
}

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

void vertex() {
	foam_uv_near = (VERTEX.xz - foam_center) / foam_coverage + 0.5;
	foam_uv_far = (VERTEX.xz - foam_center) / foam_coverage_far + 0.5;
	world_xz = VERTEX.xz;
	h_dist = distance(VERTEX, CAMERA_POSITION_WORLD);
	camera_dist = distance(VERTEX.xz, CAMERA_POSITION_WORLD.xz);
	
	VERTEX += wave(VERTEX.xz, 5);
}

void fragment() {
	// Analytical normals? Performance is better, but more complex to setup. :'(
	//vec3 w_normal = wave_normal(world_xz);
	//NORMAL = normalize((VIEW_MATRIX * vec4(w_normal, 0.0)).xyz);
	
	// Neighbor sampling normals
	vec2 pos_x = world_xz + vec2(sampling_distance, 0.0);
	vec2 pos_z = world_xz + vec2(0.0, sampling_distance);
	vec3 wave_current = vec3(world_xz.x, 0.0, world_xz.y) + wave(world_xz,3);
	vec3 tangent_x = vec3(pos_x.x, 0.0, pos_x.y) + wave(pos_x, 3) - wave_current;
	vec3 tangent_z = vec3(pos_z.x, 0.0, pos_z.y) + wave(pos_z, 3) - wave_current;
	vec3 wave_normal = cross(tangent_z, tangent_x);
	NORMAL = normalize((VIEW_MATRIX * vec4(wave_normal, 0.0)).xyz);
	
	vec4 world_pos = INV_VIEW_MATRIX * vec4(VERTEX, 1);
	float h_blend = smoothstep(0, 6, world_pos.y);
	vec3 mixed_color = mix(color, crest_color, h_blend);
	vec4 foam_near = texture(foam_map_near, foam_uv_near);
	vec4 foam_far = texture(foam_map_far, foam_uv_far);
	vec2 world_uv = world_xz / 15.0;
	float foam_fresh = texture(sea_foam, world_uv * 2.0).r;
	float foam_old = texture(sea_foam, world_uv * 12.0).r;

	//Near foam
	float near_g = depth_foam_enabled ? foam_near.g : 0.0;
	vec2 foam_near_mixed = create_mixed_foam(foam_old, foam_fresh, vec2(foam_near.r, near_g));
	
	// Far foam
	float far_g = depth_foam_enabled ? foam_far.g : 0.0;
	vec2 foam_far_mixed = create_mixed_foam(foam_old, foam_fresh, vec2(foam_far.r, far_g));
	
	// Foam edge fading
	float near_radius = foam_coverage * 0.5;
	float far_radius = foam_coverage_far * 0.5;
	float fade_near = near_foam_enabled ? smoothstep(near_radius * 0.7, near_radius, camera_dist) : 1.0;
	float fade_far = far_foam_enabled ? smoothstep(far_radius * 0.9, far_radius, camera_dist) : 0.0;
	vec2 foam = mix(foam_near_mixed, foam_far_mixed, fade_near);
	foam = mix(foam, vec2(0), fade_far);
	
	// Add foam to albedo
	mixed_color = mix(mixed_color, vec3(0.6,1,0.9), foam.x);
	mixed_color = mix(mixed_color, vec3(0.6,1,0.9), foam.y);
		
	//Refraction
	vec3 normal = normalize(NORMAL);
	vec2 dist_strength = vec2(0.025, 0.01) * 1.25;
	vec2 planned_distortion = vec2(normal.x, -normal.y) * dist_strength;
	float distance_factor = clamp(4.0 / -VERTEX.z, 0, 1);

	vec2 d_uv = SCREEN_UV + planned_distortion * distance_factor;
	float d_depth = texture(depth_texture, d_uv).r;
	
	float through_water = get_through_water(d_uv, d_depth, INV_PROJECTION_MATRIX, VERTEX.z);
	// Multiply blend with 0.8 to help with weird artifacts due to AA if needed.
	//Related to depth_texture filtering
	float blend = smoothstep(0,0.5, through_water);
	
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
	float i_noise = texture(i_noise_texture, world_xz * 0.25 + TIME * 0.02).r;
	float i_width = 0.02 + sin(TIME * 0.5) * 0.02 + i_noise * 0.04;
	if(through_water > 0.0 && through_water < i_width) {
		float fade_in = smoothstep(0, 0.1 * i_width, through_water);
		float fade_out = 1.0 - smoothstep(0.8 * i_width, i_width, through_water);
		
		mixed_color = mix(mixed_color, vec3(0.4,0.7,0.6), fade_in * fade_out);
	}
	
	float horizon_fade = smoothstep(300,500, h_dist);
	float rim_fade = smoothstep(4, 20, camera_dist);
	mixed_color = mix(mixed_color, vec3(0.0), horizon_fade);
	
	ALBEDO = mixed_color;
	EMISSION = mix(EMISSION, horizon_color, horizon_fade);
	RIM = mix(3,0, rim_fade);
	ROUGHNESS = 0.01;
	SPECULAR = mix(SPECULAR, 0.0, horizon_fade);
}
