shader_type spatial;
// Glowing magic surfaces: beams, bubbles, rings, fire columns. Additive, with a fresnel rim,
// scrolling noise that makes the energy flow, and a fade from bottom to top for columns.
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform vec4 core : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform float intensity = 2.0;
uniform float rim = 1.5;             // 0 = flat, higher = only the edges glow (bubbles)
uniform float flow = 1.2;            // noise scroll speed
uniform float noise_scale = 3.0;
uniform float v_fade = 0.0;          // 1 = fade toward the top of the mesh (columns)
uniform float alpha = 1.0;           // animated from script for fade in/out
uniform sampler2D noise_tex : repeat_enable, filter_linear;

void fragment() {
	vec2 uv = UV * noise_scale;
	float n = texture(noise_tex, uv + vec2(0.0, -TIME * flow)).r;
	float n2 = texture(noise_tex, uv * 1.7 + vec2(TIME * flow * 0.3, -TIME * flow * 0.6)).r;
	float e = n * 0.6 + n2 * 0.6;
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), rim);
	float body = mix(1.0, fres, clamp(rim / 3.0, 0.0, 1.0));
	float vf = mix(1.0, pow(clamp(1.0 - UV.y, 0.0, 1.0), 1.5), v_fade);
	float a = clamp(body * e * vf * alpha, 0.0, 1.0);
	vec3 c = mix(color.rgb, core.rgb, smoothstep(0.55, 1.1, e * body));
	ALBEDO = c * intensity * a;
}
