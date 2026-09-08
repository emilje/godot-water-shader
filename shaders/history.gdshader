shader_type canvas_item;
uniform sampler2D current_foam;
uniform sampler2D history_foam;
uniform float delta;

void fragment() {
	vec4 current = texture(current_foam, UV);
	vec4 previous = texture(history_foam, UV);
	
	previous *= exp(-3.5 * delta);
	previous = max(previous,0.0);
	
	vec4 foam = max(current,previous);
	
	COLOR = vec4(foam.r, foam.g, 0,1);
}