shader_type canvas_item;
render_mode blend_add, unshaded;


uniform vec4 glowColor : source_color = vec4(1.0);
uniform float strength = 0.5;
uniform float glowSize = 2.0;
uniform float pulseSpeed = 1.2;

//------------------------//

float in_bounds(vec2 uv) {
	return step(0.0, uv.x) * step(0.0, uv.y) * step(uv.x, 1.0) * step(uv.y, 1.0);
}

void vertex() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	VERTEX += (UV * 2.0 - 1.0) * glowSize;
	UV = (UV * (size + glowSize * 2.0) - glowSize) / size;
}

void fragment() {
	float halo = 0.0;
	for (int i = 0; i < 12; i++) {
		float angle = float(i) * TAU / 12.0;
		vec2 offset = vec2(cos(angle), sin(angle)) * TEXTURE_PIXEL_SIZE * glowSize;
		halo += texture(TEXTURE, UV + offset).a * in_bounds(UV + offset);
		halo += texture(TEXTURE, UV + offset * 0.5).a * in_bounds(UV + offset * 0.5);
	}
	halo /= 24.0;
	float inside = texture(TEXTURE, UV).a * in_bounds(UV);
	float pulse = 0.6 + 0.4 * sin(TIME * pulseSpeed);
	float glow = (halo * (1.0 - inside) + inside * 0.15) * pulse;
	COLOR = vec4(glowColor.rgb, clamp(glow * strength, 0.0, 1.0));
}
