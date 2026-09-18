shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;


uniform vec4 glowColor : source_color = vec4(0.62, 0.3, 1.0, 1.0);
uniform vec4 coreColor : source_color = vec4(0.87, 0.75, 1.0, 1.0);
uniform vec4 voidColor : source_color = vec4(0.05, 0.0, 0.12, 1.0);
uniform float radius = 0.6;
uniform float rimWidth = 0.08;
uniform float haloWidth = 0.35;
uniform float wobble = 0.12;
uniform float arms = 3.0;
uniform float twist = 3.0;
uniform float spinSpeed = 2.5;
uniform float intensity = 1.0;
uniform float flash = 0.0;

varying vec4 tint;

//------------------------//

float square(float value) {
	return value * value;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec2 rotate(vec2 p, float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0 / radius;
	float dist = length(p);
	vec2 direction = p / max(dist, 0.001);
	float edge = 1.0 + (noise(direction * 2.0 + vec2(TIME * 1.7, TIME * -1.1)) - 0.5) * wobble * 2.0;
	float r = dist / edge;
	float inside = 1.0 - smoothstep(0.9, 1.0, r);
	float rim = exp(-square((r - 1.0) / rimWidth));
	float halo = exp(-square(max(r - 1.0, 0.0) / haloWidth)) * smoothstep(0.7, 1.0, r) * (1.0 - smoothstep(1.4, 1.66, dist));
	float angle = atan(p.y, p.x + 0.00001);
	float spiral = 0.5 + 0.5 * sin(angle * arms + log(max(r, 0.03)) * twist - TIME * spinSpeed);
	vec2 swirled = rotate(p, TIME * spinSpeed * 0.6 + (1.0 - r) * twist * 0.8);
	float cloud = noise(swirled * 2.5 + 7.0) * 0.6 + noise(swirled * 5.0 - 3.0) * 0.4;
	float depth = smoothstep(0.0, 0.9, r);
	float swirl = pow(spiral, 3.0) * (0.5 + cloud) * inside * depth;
	float innerGlow = square(smoothstep(0.3, 1.0, r)) * inside;
	float eye = exp(-square(r / 0.3));
	vec3 light = glowColor.rgb * (halo * 0.55 + innerGlow * 0.6 + swirl * 0.8);
	light += coreColor.rgb * (rim * 0.95 + swirl * square(depth) * 0.3 + eye * 0.12);
	light += mix(coreColor.rgb, vec3(1.0), 0.5) * flash * (inside * 0.45 + rim * 0.8 + halo * 0.3);
	light *= intensity * tint.rgb;
	float voidAlpha = inside * clamp(intensity * 1.5, 0.0, 1.0) * 0.92;
	vec3 voidLight = voidColor.rgb * (0.5 + cloud * 0.8) * voidAlpha;
	COLOR = vec4((voidLight + light) * tint.a, voidAlpha * tint.a);
}
