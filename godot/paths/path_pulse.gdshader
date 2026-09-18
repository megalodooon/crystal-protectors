shader_type canvas_item;
render_mode blend_add, unshaded;


uniform vec4 glowColor : source_color = vec4(0.62, 0.3, 1.0, 1.0);
uniform vec4 coreColor : source_color = vec4(0.9, 0.78, 1.0, 1.0);
uniform vec2 pulses[8];
uniform int pulseCount = 0;
uniform float pathLength = 100.0;
uniform float halfWidth = 10.0;
uniform float lineWidth = 1.0;
uniform float glowWidth = 3.5;
uniform float glowStrength = 0.8;
uniform float headGlow = 1.5;
uniform float headLength = 12.0;
uniform float trailLength = 60.0;
uniform float afterglow = 0.3;
uniform float opacity = 1.0;
uniform float gray = 0.0;

//------------------------//

float square(float value) {
	return value * value;
}

void fragment() {
	float along = clamp(UV.x, 0.0, pathLength);
	float across = (UV.y - 0.5) * 2.0 * halfWidth;
	float radius = length(vec2(UV.x - along, across));
	float edge = mix(COLOR.r, COLOR.g, step(0.0, across)) * halfWidth;
	float edgeFade = 1.0 - smoothstep(edge * 0.5, edge, abs(across));
	float core = 0.0;
	float glow = 0.0;
	float headCore = 0.0;
	for (int i = 0; i < pulseCount; i++) {
		float behind = pulses[i].y - along;
		float started = smoothstep(pulses[i].x - 2.0, pulses[i].x, along);
		float capsule = length(vec2(max(-behind, 0.0), radius));
		float trail = mix(mix(afterglow, 1.0, gray), 1.0, square(1.0 - clamp(behind / trailLength, 0.0, 1.0))) * started;
		float tail = exp(-square(max(behind, 0.0) / headLength)) * started;
		core = max(core, exp(-square(capsule / lineWidth)) * trail);
		glow = max(glow, exp(-square(capsule / glowWidth)) * (trail + tail * headGlow * 0.4));
		headCore = max(headCore, exp(-square(capsule / (lineWidth * 1.6))) * tail);
	}
	vec3 color = glowColor.rgb * glow * glowStrength * edgeFade;
	color += coreColor.rgb * core;
	color += mix(coreColor.rgb, vec3(1.0), 0.6) * headCore * headGlow * 0.8;
	color = mix(color, vec3(dot(color, vec3(0.2126, 0.7152, 0.0722))), gray);
	COLOR = vec4(color, opacity);
}
