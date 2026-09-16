shader_type canvas_item;


uniform float buildUp : hint_range(0.0, 1.0) = 0.0;
uniform vec4 iceColor : source_color = vec4(0.45, 0.72, 1.0, 1.0);
uniform vec4 frostColor : source_color = vec4(0.92, 0.98, 1.0, 1.0);
uniform float opacity = 0.8;

//------------------------//

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float in_bounds(vec2 uv) {
	return step(0.0, uv.x) * step(0.0, uv.y) * step(uv.x, 1.0) * step(uv.y, 1.0);
}

void fragment() {
	vec2 texel = TEXTURE_PIXEL_SIZE;
	vec2 pixel = floor(UV / texel);
	vec2 center = (pixel + 0.5) * texel;
	vec4 source = texture(TEXTURE, center);
	float edge = texture(TEXTURE, center + vec2(texel.x, 0.0)).a * in_bounds(center + vec2(texel.x, 0.0));
	edge = max(edge, texture(TEXTURE, center - vec2(texel.x, 0.0)).a * in_bounds(center - vec2(texel.x, 0.0)));
	edge = max(edge, texture(TEXTURE, center + vec2(0.0, texel.y)).a * in_bounds(center + vec2(0.0, texel.y)));
	edge = max(edge, texture(TEXTURE, center - vec2(0.0, texel.y)).a * in_bounds(center - vec2(0.0, texel.y)));
	float solid = step(0.5, source.a);
	float height = 1.0 - center.y;
	float frozen = step(height + hash(pixel) * 0.3, buildUp * 1.3);
	float light = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float sparkle = step(0.93, hash(pixel + floor(TIME * 4.0)));
	vec3 body = mix(iceColor.rgb, frostColor.rgb, clamp(light * 0.8 + sparkle, 0.0, 1.0));
	float crust = (1.0 - solid) * step(0.5, edge) * step(0.55, hash(pixel * 1.37 + 3.1));
	vec3 color = mix(iceColor.rgb, body, solid);
	COLOR = vec4(color, max(solid, crust) * opacity * frozen);
}
