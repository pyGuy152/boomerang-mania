shader_type fog;

uniform vec4 fog_color : source_color = vec4(0.7, 0.75, 0.8, 1.0);
uniform float density : hint_range(0.0, 8.0) = 1.5;
uniform float noise_scale : hint_range(0.05, 4.0) = 0.6;
uniform float contrast : hint_range(0.5, 6.0) = 2.0;  // higher = patchier, clearer gaps
uniform float coverage : hint_range(0.0, 1.0) = 0.4;  // higher = less fog
uniform vec3 wind = vec3(0.3, 0.0, 0.1);
uniform float edge_fade : hint_range(0.0, 1.0) = 0.3; // fades fog toward volume edges

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
			mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
			mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y),
		f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fog() {
	vec3 p = WORLD_POSITION * noise_scale + wind * TIME;
	float n = fbm(p);
	n = clamp((n - coverage) * contrast, 0.0, 1.0);

	// Fade out near the edges of the FogVolume box
	vec3 e = abs(UVW * 2.0 - 1.0);
	float edge = 1.0 - smoothstep(1.0 - edge_fade, 1.0, max(e.x, max(e.y, e.z)));

	DENSITY = n * density * edge;
	ALBEDO = fog_color.rgb;
}