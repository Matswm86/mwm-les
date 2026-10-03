shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;
// Inverted-hull outline (DESIGN 7.2), only on things the child can touch.
// Width grows with view distance so the line stays about 4 px on screen.

uniform vec4 color : source_color = vec4(0.11, 0.17, 0.27, 1.0);
uniform float width = 0.0035;

void vertex() {
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float scale = max(length(MODEL_MATRIX[0].xyz), 0.0001);
	VERTEX += normalize(NORMAL) * width * max(-view.z, 0.5) / scale;
}

void fragment() {
	ALBEDO = color.rgb;
}
