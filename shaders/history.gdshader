shader_type canvas_item;
uniform sampler2D current_foam: repeat_disable;
uniform sampler2D history_foam: repeat_disable;
uniform float delta;
uniform vec2 foam_history_offset;
uniform float decay_rate = 0.2;
uniform float erosion_multiplier;

uniform sampler2D erosion_noise: repeat_enable;
uniform vec2 capture_center;
uniform float capture_coverage;

void fragment() {
	vec4 current = texture(current_foam, UV);
	vec2 history_uv = UV + foam_history_offset;
	vec4 previous = vec4(0);
	
	if (all(greaterThanEqual(history_uv, vec2(0))) &&
		all(lessThanEqual(history_uv, vec2(1)))) {
		previous = texture(history_foam, history_uv);
	}
	
	vec2 world_xz = capture_center + (UV - 0.5) * capture_coverage;
	vec2 world_uv = world_xz / 15.0;
	float noise_erosion = texture(erosion_noise, world_uv * 6.0).r;
	previous.r -= noise_erosion * delta * erosion_multiplier;
	if(previous.g > 0.7) {
		previous.g -= noise_erosion * delta * erosion_multiplier * 0.1;
	}
	
	previous.r *= exp(-decay_rate * delta);
	previous.g *= exp(-decay_rate * delta * 0.1);
	
	previous = max(previous,0.0);
	
	vec4 foam = max(current,previous);
	
	COLOR = vec4(foam.r, foam.g, 0,1);
}
