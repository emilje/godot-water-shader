shader_type canvas_item;
uniform sampler2D noise: repeat_enable;
uniform float noise_intensity: hint_range(0,1) = 0.2;
uniform float noise_intensity_x: hint_range(-0.3,0.3) = 0.2;
uniform float noise_intensity_z: hint_range(-0.3,0.3) = 0.2;

vec3 gerstner(vec2 pos, vec2 direction, float amplitude, float frequency, float speed, float steepness) {
	direction = normalize(direction);
	float noise_value = texture(noise, (pos/10.0+0.5)*2.0 + TIME * direction * 0.07).r;
	float phase = (TIME * speed + dot(direction, pos) * frequency);
	vec3 displacement;
	displacement.y = sin(phase) * amplitude + noise_value * noise_intensity - noise_intensity/2.0;
	displacement.xz = direction * cos(phase) * steepness;
	
	displacement.x += noise_value * noise_intensity_x - noise_intensity_x/2.0;
	displacement.z += noise_value * noise_intensity_z - noise_intensity_z/2.0;
	
	return displacement;
}

vec3 wave(vec2 pos) {
	vec3 displacement = gerstner(pos, vec2(0,1), 0.4, 1, 1.3, 0.2);
	displacement += gerstner(pos, vec2(1,1), 0.15, 1.3, 1.6, 0.12);
	displacement += gerstner(pos, vec2(0.5,1), 0.12, 2.0, 2.0, 0.17);
	displacement += gerstner(pos, vec2(-0.4,1), 0.01, 3.0, 3.0, 0.1);
	displacement += gerstner(pos, vec2(-0.2,0.7), 0.025, 4.0, 4.0, 0.08);
	
	return displacement;
}

void fragment() {
	vec2 pos = (UV-0.5)*10.0;
	vec3 displacement = wave(pos);
	
	COLOR = vec4(displacement,1);
}
