// Calm pond water.
//  - clear at the edges (you see the sandy bed, with sunlight caustics dancing on it),
//    deepening to teal in the middle
//  - slow, broad ripples that stir a little more when the wind gusts
//  - mirror-like reflections of sky, trees and houses (sky light + screen-space reflections)
//  - small waves of soft foam lapping the shore, a wet contact line
//  - sun glitter where ripples catch the light; warm at sunset, silver under the moon
//  - fish ripple rings (set from script) spreading and fading
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

uniform sampler2D noise_fine : filter_linear_mipmap, repeat_enable;
uniform sampler2D noise_big : filter_linear_mipmap, repeat_enable;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear;
uniform vec3 shallow : source_color = vec3(0.30, 0.62, 0.62);
uniform vec3 mid : source_color = vec3(0.09, 0.38, 0.45);
uniform vec3 deep : source_color = vec3(0.035, 0.16, 0.25);
uniform vec3 sun_dir = vec3(0.3, 0.8, 0.4);     // toward the sun (or moon at night)
uniform vec3 sun_col : source_color = vec3(1.0, 0.95, 0.85);
uniform float daylight = 1.0;
global uniform float wind_time;
uniform vec4 rings[6];                          // xy = centre, z = age (s), w = strength
uniform sampler2D reflection_tex : filter_linear, repeat_disable;   // mirrored camera (see src/world/water.gd)
uniform float reflect_amount = 1.0;
uniform float glow = 0.0;                        // lava: the water glows with its own colour
uniform sampler2D world_mask : filter_linear, repeat_disable;   // a = pond area
uniform float half_size = 128.0;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// the gentlest swell, so the surface is never glassy-flat at the shore
	VERTEX.y += (sin(wpos.x * 0.6 + wind_time * 0.7) + sin(wpos.z * 0.5 - wind_time * 0.55)) * 0.012;
}

// smooth height field of the ripples (broad and slow)
float ripple_h(vec2 p, float t, float gust) {
	float h = 0.0;
	h += texture(noise_big, p / 11.0 + vec2(t * 0.011, t * 0.007)).r * 1.0;
	h += texture(noise_big, p / 6.5 - vec2(t * 0.009, -t * 0.013)).r * 0.6;
	h += texture(noise_fine, p / 2.2 + vec2(t * 0.02, t * 0.015)).r * (0.08 + gust * 0.22);
	return h;
}

void fragment() {
	vec2 p = wpos.xz;
	if (texture(world_mask, (p + half_size) / (2.0 * half_size)).a < 0.02) discard;   // only the pond, not every hollow
	float t = wind_time;
	vec2 wdir = normalize(vec2(1.0, 0.35));
	float gust = smoothstep(0.35, 0.85, texture(noise_big, p / 38.0 - wdir * t * 0.035).r);
	float e = 0.12;
	float h0 = ripple_h(p, t, gust);
	float hx = ripple_h(p + vec2(e, 0.0), t, gust);
	float hz = ripple_h(p + vec2(0.0, e), t, gust);
	vec2 slope = vec2(h0 - hx, h0 - hz) / e * (0.05 + gust * 0.05);
	// fish rings: expanding circular ripples
	for (int i = 0; i < 6; i++) {
		vec4 r = rings[i];
		if (r.w <= 0.0) continue;
		vec2 d = p - r.xy; float dist = length(d);
		float front = r.z * 0.55;
		float wave = sin((dist - front) * 18.0) * exp(-pow((dist - front) * 3.0, 2.0)) * r.w * exp(-r.z * 0.9);
		slope += normalize(d + 0.0001) * wave * 0.35;
	}
	vec3 n = normalize(vec3(slope.x, 1.0, slope.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);

	// how deep the water is under this pixel (along the view ray)
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 vp = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	vp.xyz /= vp.w;
	float ray_depth = clamp(-vp.z + VERTEX.z, 0.0, 30.0);
	vec3 bed_w = (INV_VIEW_MATRIX * vec4(vp.xyz, 1.0)).xyz;
	float depth = clamp(wpos.y - bed_w.y, 0.0, 10.0);            // vertical depth: nicer colour bands

	// what lies beneath, bent by the ripples
	vec2 ruv = SCREEN_UV + slope * 0.03 * smoothstep(0.0, 0.6, depth);
	vec3 under = textureLod(screen_tex, ruv, 0.0).rgb;
	// caustics: two drifting ridged noises; bright light lines on the shallow bed
	vec2 cp = bed_w.xz;
	float c1 = texture(noise_fine, cp / 2.3 + vec2(t * 0.03, t * 0.02)).r;
	float c2 = texture(noise_fine, cp / 1.9 - vec2(t * 0.025, -t * 0.03) + 0.5).r;
	float caus = pow(1.0 - abs(c1 - c2), 10.0) * smoothstep(0.0, 0.25, depth) * (1.0 - smoothstep(0.6, 2.0, depth));
	under += sun_col * caus * 0.55 * daylight;
	under *= mix(vec3(1.0), shallow * 1.1, smoothstep(0.0, 0.35, depth));   // tinted by the water

	float murk = 1.0 - exp(-ray_depth * 1.2);
	vec3 body = mix(mid, deep, smoothstep(0.4, 2.2, depth));
	vec3 col = mix(under, body * (0.35 + 0.65 * daylight), murk);

	// shore: little waves of soft foam rolling in, and a wet contact line
	float fn = texture(noise_fine, p * 0.9 + vec2(t * 0.04, 0.0)).r;
	float band = fract(depth * 5.0 - t * 0.12 + fn * 0.5);
	float waves = smoothstep(0.0, 0.08, band) * smoothstep(0.35, 0.12, band) * (1.0 - smoothstep(0.05, 0.28, depth));
	float contact = (1.0 - smoothstep(0.0, 0.03, depth + (fn - 0.5) * 0.03)) * 0.6;
	float foam = clamp(waves * 0.55 + contact * 0.8, 0.0, 1.0) * smoothstep(0.25, 0.55, fn + 0.2);
	col = mix(col, vec3(0.93, 0.96, 0.95) * (0.3 + 0.7 * daylight), foam * 0.75);

	// sun (or moon) glitter where ripples face the light just right
	vec3 v = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec3 r = reflect(-v, n);
	float glint = pow(max(dot(r, normalize(sun_dir)), 0.0), 300.0);
	float spark = step(0.72, texture(noise_fine, p * 3.0 + t * 0.07).r) * pow(max(dot(r, normalize(sun_dir)), 0.0), 40.0);
	EMISSION = sun_col * (glint * 2.2 + spark * 0.9) * (1.0 - foam) * (0.25 + 0.75 * daylight);

	// reflections: the mirrored view of trees, houses and sky, rippled
	float fres = 0.03 + 0.97 * pow(1.0 - max(dot(n, v), 0.0), 5.0);
	vec3 refl = texture(reflection_tex, vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y) + slope * vec2(0.05, 0.08)).rgb;
	refl *= mix(vec3(1.0), shallow * 1.25, 0.35);
	col = mix(col, refl * 0.85, clamp(0.06 + fres * reflect_amount * 0.8, 0.0, 0.5) * (1.0 - foam * 0.8));

	ALBEDO = col;
	EMISSION += col * glow * (0.6 + 0.4 * texture(noise_big, p * 0.05 + t * 0.01).r);
	ROUGHNESS = mix(0.03, 0.5, foam);
	SPECULAR = 0.5;
	METALLIC = 0.0;
}
