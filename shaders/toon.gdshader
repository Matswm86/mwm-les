shader_type spatial;
render_mode specular_disabled;
// Cel shading (DESIGN 7.1): one hard light band from a custom light(), shadow
// band tinted cool blue, flat ambient from the environment. World props fade
// from grey to colour per restored zone (global zone_a/b/c: x, radius, z, amount).

global uniform vec4 zone_a;
global uniform vec4 zone_b;
global uniform vec4 zone_c;
global uniform float world_color;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform bool use_vertex_color = false;
uniform bool use_zones = false;
uniform float grey_floor : hint_range(0.0, 1.0) = 0.12;
uniform vec4 shadow_tint : source_color = vec4(0.16, 0.21, 0.31, 1.0);
uniform float shadow_mix : hint_range(0.0, 1.0) = 0.55;
uniform float ramp_edge : hint_range(-1.0, 1.0) = 0.2;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// characters skip received shadows (blob shadows instead, DESIGN 6): no acne on round bodies
uniform bool receive_shadow = true;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float zone_amount(vec4 z) {
	float d = distance(world_pos.xz, vec2(z.x, z.z));
	return z.w * (1.0 - smoothstep(z.y * 0.55, z.y, d));
}

void fragment() {
	vec3 c = albedo.rgb * texture(albedo_tex, UV).rgb;
	if (use_vertex_color) {
		c *= COLOR.rgb;
	}
	if (use_zones) {
		float s = max(zone_amount(zone_a), max(zone_amount(zone_b), zone_amount(zone_c)));
		s = max(s, max(grey_floor, world_color));
		float l = dot(c, vec3(0.299, 0.587, 0.114));
		c = mix(vec3(l) * 0.92 + 0.03, c, s);
	}
	ALBEDO = c;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = emission.rgb + vec3(rim * rim_strength);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// fade received shadow out near the terminator, where the band already darkens:
	// removes shadow-map stair steps on gentle slopes
	float att = receive_shadow ? mix(1.0, ATTENUATION, smoothstep(ramp_edge, ramp_edge + 0.3, ndl)) : 1.0;
	float band = smoothstep(ramp_edge - 0.02, ramp_edge + 0.02, ndl * att);
	vec3 shade = mix(vec3(1.0), shadow_tint.rgb * 2.2, shadow_mix);
	DIFFUSE_LIGHT += mix(shade, vec3(1.0), band) * LIGHT_COLOR / PI;
}
