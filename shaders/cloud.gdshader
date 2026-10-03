shader_type spatial;
render_mode unshaded, shadows_disabled;
// Puffy painted clouds: lit top, soft blue underside, no lighting cost.

uniform vec4 top : source_color = vec4(0.99, 1.0, 1.0, 1.0);
uniform vec4 under : source_color = vec4(0.74, 0.85, 0.96, 1.0);

varying vec3 wn;

void vertex() {
	wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	float k = smoothstep(-0.25, 0.05, normalize(wn).y);
	ALBEDO = mix(under.rgb, top.rgb, k);
}
