shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;


uniform vec4 darkColor : source_color = vec4(0.4, 0.25, 0.25, 1.0);
uniform vec4 mainColor : source_color = vec4(0.8, 0.5, 0.45, 1.0);
uniform vec4 lightColor : source_color = vec4(1.0, 0.85, 0.8, 1.0);
uniform sampler2D streakNoise : repeat_enable, filter_linear;
uniform float head = 1.0;
uniform float trail = 0.5;
uniform float opacity = 1.0;
uniform float meshInner = 0.0;
uniform float meshOuter = 32.0;
uniform float bandInner = 10.0;
uniform float bandOuter = 24.0;
uniform float arcLength = 60.0;
uniform float glow = 0.0;
uniform float core = 0.0;
uniform float tipGlow = 0.0;
uniform float streaks = 0.0;
uniform float chromatic = 0.0;

//------------------------//

float square(float value) {
	return value * value;
}

float along_fade(float u) {
	float behind = head - u;
	float local = clamp(behind / max(trail, 0.001), 0.0, 1.0);
	return smoothstep(-0.02, 0.02, behind) * pow(1.0 - local, 1.5);
}

float rim_edge(float r) {
	return 1.0 - smoothstep(bandOuter - 0.75, bandOuter + 0.75, r);
}

float crescent(float r, float u) {
	float local = clamp((head - u) / max(trail, 0.001), 0.0, 1.0);
	float thickness = (bandOuter - bandInner) * mix(1.0, 0.2, local);
	float inner = bandOuter - thickness;
	float fill = smoothstep(inner - 1.0, bandOuter - thickness * 0.35, r);
	return fill * rim_edge(r) * along_fade(u);
}

void fragment() {
	float u = UV.x;
	float r = mix(meshInner, meshOuter, UV.y);
	float noise = texture(streakNoise, vec2(u * arcLength / 256.0 - head * 0.25, r / 7.0)).r;
	float streak = mix(1.0, clamp(0.2 + noise * 1.6, 0.0, 1.5), streaks);
	float shape = crescent(r, u);
	float alpha = clamp(shape * streak, 0.0, 1.0) * opacity;
	vec3 bodyColor = mix(darkColor.rgb, mainColor.rgb, shape);
	float fade = along_fade(u);
	float bandWidth = max(bandOuter - bandInner, 1.0);
	float rim = exp(-square((r - bandOuter + 1.0) / 1.2)) * fade;
	float bloom = exp(-abs(r - bandOuter + 1.0) / bandWidth * 4.0) * fade;
	float tip = exp(-square((u - head) * arcLength / 4.0)) * exp(-square((r - bandOuter + 1.5) / 3.0));
	float fringeRed = max(rim_edge(r - chromatic) - rim_edge(r), 0.0) * fade;
	float fringeBlue = max(rim_edge(r) - rim_edge(r + chromatic), 0.0) * fade * 0.7;
	vec3 added = lightColor.rgb * rim * core * 1.2;
	added += mainColor.rgb * bloom * glow * 0.7;
	added += lightColor.rgb * tip * tipGlow;
	added *= mix(1.0, streak, 0.5);
	added += vec3(1.0, 0.15, 0.3) * fringeRed + vec3(0.2, 0.5, 1.0) * fringeBlue;
	COLOR = vec4(bodyColor * alpha + added * opacity, alpha);
}
