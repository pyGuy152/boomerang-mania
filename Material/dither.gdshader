shader_type spatial;
render_mode ambient_light_disabled, specular_disabled;

varying vec2 screen_px;

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float use_texture : hint_range(0.0, 1.0) = 1.0;

uniform float global_size : hint_range(0.1, 1.0) = 0.5;
uniform float lit_boost : hint_range(0.5, 3.0) = 1.0; // brightness of fully lit areas

group_uniforms layer1;
uniform float l1_threshold : hint_range(0.0, 1.0) = 0.75;
uniform float l1_size : hint_range(1.0, 32.0) = 4.0;
uniform float l1_strength : hint_range(0.0, 4.0) = 2.0;
uniform float l1_darkness : hint_range(0.0, 1.0) = 0.3;

group_uniforms layer2;
uniform float l2_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float l2_size : hint_range(1.0, 32.0) = 4.0;
uniform float l2_strength : hint_range(0.0, 4.0) = 2.0;
uniform float l2_darkness : hint_range(0.0, 1.0) = 0.4;

group_uniforms layer3;
uniform float l3_threshold : hint_range(0.0, 1.0) = 0.2;
uniform float l3_size : hint_range(1.0, 32.0) = 4.0;
uniform float l3_strength : hint_range(0.0, 4.0) = 2.0;
uniform float l3_darkness : hint_range(0.0, 1.0) = 0.6;

// 8x8 Bayer matrix, computed with bit tricks (no array needed)
float bayer8(ivec2 p) {
	int x = p.x & 7;
	int y = (p.x ^ p.y) & 7;
	int v = ((y & 1) << 5) | ((x & 1) << 4) | ((y & 2) << 2)
		| ((x & 2) << 1) | ((y & 4) >> 1) | ((x & 4) >> 2);
	return (float(v) + 0.5) / 64.0;
}

float dither_layer(float lit, float thr, float size, float strength, float darkness, ivec2 offset) {
	float c = clamp((1.0 - lit / max(thr, 0.001)) * strength, 0.0, 1.0);
	ivec2 p = ivec2(floor(screen_px / (size * global_size))) + offset;
	float on = step(bayer8(p), c);
	return mix(1.0, 1.0 - darkness, on);
}

void fragment() {
	vec3 tex = texture(albedo_tex, UV).rgb;
	ALBEDO = mix(tint.rgb, tex * tint.rgb, use_texture);
	screen_px = FRAGCOORD.xy;
}
void light() {
	float lit = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;

	float shade = 1.0;
	shade *= dither_layer(lit, l1_threshold, l1_size, l1_strength, l1_darkness, ivec2(0, 0));
	shade *= dither_layer(lit, l2_threshold, l2_size, l2_strength, l2_darkness, ivec2(3, 5));
	shade *= dither_layer(lit, l3_threshold, l3_size, l3_strength, l3_darkness, ivec2(6, 2));

	// Light is flat (not smooth), so only the dither creates shading
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * lit_boost * shade / PI * step(0.001, lit * 1000.0);
}