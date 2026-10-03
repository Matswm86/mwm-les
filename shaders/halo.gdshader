shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, cull_disabled;
// Camera-facing additive halo behind letters (DESIGN 7.3): glow without bloom.

uniform vec4 color : source_color = vec4(1.0, 0.76, 0.10, 1.0);
uniform float strength = 0.4;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float a = pow(clamp(1.0 - r, 0.0, 1.0), 2.0);
	ALBEDO = color.rgb * a * strength;
}
