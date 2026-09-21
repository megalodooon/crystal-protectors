shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;


uniform vec4 darkColor : source_color = vec4(0.2, 0.15, 0.45, 1.0);
uniform vec4 mainColor : source_color = vec4(0.5, 0.4, 1.0, 1.0);
uniform vec4 lightColor : source_color = vec4(0.85, 0.8, 1.0, 1.0);
uniform sampler2D streakNoise : repeat_enable, filter_linear;
uniform float padding = 3.0;
uniform float glow = 0.0;
uniform float core = 0.3;
uniform float streaks = 0.1;
uniform float helix = 0.0;
uniform float sparkles = 0.0;
uniform float chromatic = 0.0;
uniform float flowSpeed = 2.2;
uniform float helixTwist = 20.0;
uniform float helixSpeed = 14.0;

//------------------------//

float square(float value) {
	return value * value;
}

void fragment() {
	float along = UV.x;
	float across = (UV.y * 2.0 - 1.0) * padding;
	float fade = COLOR.a;
	float noise = texture(streakNoise, vec2(along * 1.4 - TIME * flowSpeed, UV.y * 0.9)).r;
	float streak = mix(1.0, clamp(0.2 + noise * 1.7, 0.0, 1.6), streaks);
	float body = (1.0 - smoothstep(0.3, 1.0, abs(across))) * fade;
	float alpha = clamp(body * streak, 0.0, 1.0);
	vec3 bodyColor = mix(darkColor.rgb, mainColor.rgb, clamp(body * 1.5, 0.0, 1.0));
	float coreLine = exp(-square(across / 0.35)) * fade * (1.0 - along * 0.6);
	float halo = exp(-square(across / padding) * 2.5) * fade;
	float twist = sin(along * helixTwist - TIME * helixSpeed);
	float strands = exp(-square((across - twist * 1.15) / 0.3)) + exp(-square((across + twist * 1.15) / 0.3));
	strands *= helix * fade * smoothstep(0.02, 0.2, along);
	float glintNoise = texture(streakNoise, vec2(along * 0.6 + TIME * 0.35, UV.y * 0.25 + 0.5)).r;
	float glint = smoothstep(0.7, 0.82, glintNoise) * exp(-square(across / 1.1)) * sparkles * fade;
	float rim = smoothstep(0.55, 1.0, abs(across)) * (1.0 - smoothstep(1.0, 1.0 + chromatic * 0.6, abs(across))) * fade;
	vec3 fringe = mix(vec3(0.2, 0.5, 1.0), vec3(1.0, 0.15, 0.35), step(0.0, across)) * rim * min(chromatic, 1.0) * 0.45;
	vec3 added = lightColor.rgb * coreLine * core * 1.5;
	added += mainColor.rgb * halo * glow * 0.6;
	added += lightColor.rgb * strands * 0.75;
	added *= mix(1.0, streak, 0.45);
	added += vec3(1.0) * glint * 1.4;
	added += fringe;
	COLOR = vec4(bodyColor * alpha + added, alpha);
}
