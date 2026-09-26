shader_type canvas_item;
// A Diablo-style orb: liquid (health red, mana blue, rage ember) sloshing inside a glass ball.
// fill 0..1 sets the level; the surface rolls gently; the liquid swirls and glows; the glass has a
// highlight and a darker rim. Drawn on a square ColorRect; the bronze frame sits on top.

uniform float fill : hint_range(0.0, 1.0) = 0.7;
uniform vec4 deep : source_color = vec4(0.35, 0.02, 0.02, 1.0);
uniform vec4 bright : source_color = vec4(1.0, 0.25, 0.15, 1.0);
uniform float swirl = 1.0;
uniform float flash = 0.0;          // brief brighten when hit or healed

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * vnoise(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; }
	return v;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;               // -1..1
	float r = length(uv);
	if (r > 1.0) discard;
	float t = TIME;
	// the liquid's surface: a gentle double wave
	float level = 1.0 - fill * 2.0;         // in uv.y (down is +)
	float wave = sin(uv.x * 3.1 + t * 1.3) * 0.035 + sin(uv.x * 7.3 - t * 2.1) * 0.012;
	float surf = level + wave * smoothstep(0.0, 0.08, fill) * smoothstep(1.0, 0.92, fill);
	float inside = smoothstep(surf - 0.01, surf + 0.01, uv.y);
	// swirling glow inside the liquid
	vec2 q = uv * 1.6;
	float a = atan(uv.y, uv.x) + t * 0.15 * swirl;
	vec2 sw = vec2(cos(a), sin(a)) * r * 2.2;
	float n = fbm(sw + vec2(t * 0.25, -t * 0.4) + fbm(q * 1.3 - t * 0.2) * 1.5);
	vec3 liquid = mix(deep.rgb, bright.rgb, smoothstep(0.25, 0.85, n));
	// spherical shading: darker toward the edge, a hot core near the top of the liquid
	float sph = sqrt(max(0.0, 1.0 - r * r));
	liquid *= 0.35 + 0.85 * sph;
	liquid += bright.rgb * 0.35 * smoothstep(0.06, 0.0, abs(uv.y - surf)) * inside;    // the bright meniscus
	// rising bubbles
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float bx = (hash(vec2(fi, 3.1)) - 0.5) * 1.3;
		float by = 1.0 - mod(t * (0.12 + 0.08 * hash(vec2(fi, 7.7))) + hash(vec2(fi, 1.9)), 1.0) * 2.0;
		float br = 0.025 + 0.02 * hash(vec2(fi, 5.3));
		float bd = length(uv - vec2(bx + sin(t + fi) * 0.04, by));
		liquid += bright.rgb * 0.6 * smoothstep(br, br * 0.4, bd) * step(surf, by);
	}
	// the empty part of the glass: dark, faintly tinted
	vec3 empty = mix(vec3(0.02, 0.02, 0.03), deep.rgb * 0.25, 0.4) * (0.4 + 0.6 * sph);
	vec3 col = mix(empty, liquid, inside);
	col *= 1.0 + flash * 0.6;
	// glass: a curved highlight top-left, a rim of reflected light, a soft shadow at the bottom
	float hl = smoothstep(0.34, 0.0, length((uv - vec2(-0.36, -0.46)) * vec2(1.0, 1.6)));
	col += vec3(1.0, 0.97, 0.92) * hl * 0.55;
	float rim = smoothstep(0.78, 1.0, r);
	col += vec3(0.8, 0.85, 1.0) * rim * 0.18 * smoothstep(0.2, -0.6, uv.y);
	col *= 1.0 - 0.45 * smoothstep(0.7, 1.0, r) * smoothstep(-0.2, 0.8, uv.y);
	COLOR = vec4(col, smoothstep(1.0, 0.985, r));
}
