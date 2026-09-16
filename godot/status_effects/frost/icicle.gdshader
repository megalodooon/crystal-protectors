shader_type canvas_item;


uniform vec4 glowColor : source_color = vec4(0.45, 0.72, 1.0, 1.0);
uniform float glowSize = 2.0;
uniform float glowStrength = 0.45;

varying vec4 tint;

//------------------------//

float in_bounds(vec2 uv) {
	return step(0.0, uv.x) * step(0.0, uv.y) * step(uv.x, 1.0) * step(uv.y, 1.0);
}

void vertex() {
	tint = COLOR;
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	VERTEX += (UV * 2.0 - 1.0) * glowSize;
	UV = (UV * (size + glowSize * 2.0) - glowSize) / size;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	source.a *= in_bounds(UV);
	float halo = 0.0;
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * TAU / 8.0;
		vec2 offset = vec2(cos(angle), sin(angle)) * TEXTURE_PIXEL_SIZE * glowSize;
		halo += texture(TEXTURE, UV + offset).a * in_bounds(UV + offset);
		halo += texture(TEXTURE, UV + offset * 0.5).a * in_bounds(UV + offset * 0.5);
	}
	halo = halo / 16.0 * glowStrength;
	vec3 color = mix(glowColor.rgb, source.rgb, source.a);
	COLOR = vec4(color, max(source.a, halo) * tint.a);
}
