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
	float world_y = world_pos.y;
	
	// In compatibility, remap values to 0-1. Use HDR 2D seems to not work when saving color data into ALBEDO of a 3d mesh.
	// Seems to work fine for color rects in 2d.
	// Adjust this values depending on your approximate wave heights in the world to get the precision you need.
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	const float Y_MIN = -10.0;
	const float Y_MAX =  10.0;

	float encoded_y = (world_pos.y - Y_MIN) / (Y_MAX - Y_MIN);
	world_y = clamp(encoded_y, 0.0, 1.0);
	#endif
		
	ALBEDO = vec3(world_y);
}