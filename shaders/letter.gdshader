shader_type spatial;
render_mode unshaded, shadows_disabled;
// Gold letters (DESIGN 7.3): unshaded so a target never hides in shadow,
// front face gold, bevel/sides lighter, plus a rim and an optional pulse.

uniform vec4 gold : source_color = vec4(1.0, 0.76, 0.10, 1.0);
uniform vec4 bevel : source_color = vec4(1.0, 0.89, 0.54, 1.0);
uniform vec4 deep : source_color = vec4(0.93, 0.55, 0.05, 1.0);
uniform float pulse = 0.0;

varying vec3 obj_normal;
varying float obj_y;

void vertex() {
	obj_normal = NORMAL;
	obj_y = VERTEX.y;
}

void fragment() {
	float front = abs(normalize(obj_normal).z);
	vec3 face = mix(deep.rgb, gold.rgb, smoothstep(-0.6, 0.6, obj_y));
	vec3 c = mix(bevel.rgb, face, smoothstep(0.6, 0.9, front));
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	c += vec3(rim * 0.25);
	c = mix(c, vec3(1.0, 0.97, 0.8), pulse * 0.45);
	ALBEDO = c;
}
