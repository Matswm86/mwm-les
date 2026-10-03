shader_type spatial;
render_mode unshaded, shadows_disabled;
// Painted sea (DESIGN 7.1): no depth or screen reads. Shallow tint near the
// islands, drifting foam streaks, fade to the horizon colour far away.

uniform vec4 deep : source_color = vec4(0.12, 0.44, 0.85, 1.0);
uniform vec4 shallow : source_color = vec4(0.25, 0.72, 0.91, 1.0);
uniform vec4 foam : source_color = vec4(0.96, 0.98, 1.0, 1.0);
uniform vec4 horizon : source_color = vec4(0.85, 0.95, 1.0, 1.0);
uniform vec4 islands[3];  // x, z, coast radius, unused
uniform float shallow_width = 7.0;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += 0.07 * sin(wpos.x * 0.35 + TIME * 1.1) + 0.05 * sin(wpos.z * 0.45 + TIME * 0.8);
}

void fragment() {
	float d = 1e5;
	for (int i = 0; i < 3; i++) {
		if (islands[i].z > 0.0) {
			d = min(d, distance(wpos.xz, islands[i].xy) - islands[i].z);
		}
	}
	float k = 1.0 - smoothstep(0.0, shallow_width, d);
	vec3 c = mix(deep.rgb, shallow.rgb, k * k);
	// thin painted wave lines: stretched along x, sparse, drifting
	vec2 p = wpos.xz * vec2(0.09, 0.32) + vec2(TIME * 0.03, TIME * 0.02);
	float n = sin(p.x * 3.1 + sin(p.y * 2.3 + TIME * 0.5) * 1.6) * sin(p.y * 2.7 + sin(p.x * 1.7 - TIME * 0.4) * 1.4);
	float n2 = sin(wpos.x * 0.05 + 1.7) * sin(wpos.z * 0.07 - 0.6);
	float streak = smoothstep(0.93, 0.95, n) * smoothstep(-0.2, 0.3, n2);
	c = mix(c, foam.rgb, streak * 0.85);
	float far = smoothstep(55.0, 170.0, length(wpos.xz - CAMERA_POSITION_WORLD.xz));
	ALBEDO = mix(c, horizon.rgb, far * 0.75);
}
