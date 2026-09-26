shader_type canvas_item;
// A filled bar that looks like glass over liquid colour: rounded shading, a bright band along the top,
// a slow shimmer running along it. The colour comes from the ColorRect's own colour.
uniform float shimmer = 0.18;

void fragment() {
	vec4 c = COLOR;
	float v = UV.y;
	float body = 0.62 + 0.55 * sin(clamp(v, 0.0, 1.0) * 3.14159);
	float hl = exp(-pow((v - 0.24) / 0.11, 2.0)) * 0.45;
	float s = exp(-pow((fract(UV.x * 0.35 - TIME * 0.08) - 0.5) * 7.0, 2.0)) * shimmer;
	float dark = smoothstep(0.7, 1.0, v) * 0.35;
	c.rgb = c.rgb * (body - dark) + vec3(hl + s) * (0.6 + 0.4 * c.rgb);
	COLOR = c;
}
