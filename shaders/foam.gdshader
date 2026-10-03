shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled;
// Shoreline foam ring (UV.x around the coast, UV.y 0 at the sand, 1 outside).
// Hard-edged alpha scissor, like painted foam: no sorting, no blending cost.

uniform vec4 foam : source_color = vec4(0.96, 0.98, 1.0, 1.0);

void fragment() {
	float v = UV.y;
	float a = UV.x * 6.2832;
	float wob = sin(a * 37.0 + TIME * 1.3) * 0.05 + sin(a * 13.0 - TIME * 0.9) * 0.05;
	float inner = 1.0 - smoothstep(0.30 + wob, 0.33 + wob, v);
	float t = fract(TIME * 0.11);
	float ring = 0.48 + t * 0.45 + wob * 0.6;
	float band = (1.0 - smoothstep(0.035, 0.05, abs(v - ring))) * step(t, 0.8);
	ALBEDO = foam.rgb;
	ALPHA = max(inner, band);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
