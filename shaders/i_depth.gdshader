shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled;
uniform sampler2D depth_texture: hint_depth_texture;

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).r;
	
	#if(CURRENT_RENDERER == RENDERER_COMPATIBILITY)
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	#else
	vec3 ndc = vec3(SCREEN_UV  * 2.0 - 1.0, depth);
	#endif
	
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1);
	vec3 world_pos = world.xyz / world.w;
		
	ALBEDO = vec3(world_pos.y);
}
