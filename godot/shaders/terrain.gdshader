// Ashvale ground: painterly meadow greens that drift in colour across the land, worn dirt roads,
// cobbled town streets, moss-dark forest floor, sandy pond shores and rock on steep slopes.
// Everything is placed by world position, so it never tiles visibly and matches the grass on top.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D world_mask : filter_linear, repeat_disable;   // r road, g cobbles, b town, a shore
uniform sampler2D noise_big : filter_linear_mipmap, repeat_enable;   // seamless value noise
uniform sampler2D noise_fine : filter_linear_mipmap, repeat_enable;
uniform sampler2D cobble_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cobble_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float half_size = 128.0;
uniform float water_h = 0.35;

uniform vec3 grass_a : source_color = vec3(0.38, 0.56, 0.20);   // lush
uniform vec3 grass_b : source_color = vec3(0.60, 0.64, 0.28);   // sunny, drier
uniform vec3 grass_c : source_color = vec3(0.27, 0.45, 0.18);   // deep
uniform vec3 dirt_a : source_color = vec3(0.47, 0.36, 0.24);
uniform vec3 dirt_b : source_color = vec3(0.60, 0.49, 0.34);
uniform vec3 sand : source_color = vec3(0.60, 0.55, 0.42);
uniform vec3 mud : source_color = vec3(0.28, 0.25, 0.18);

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// the same meadow colour the grass blades use, so blades grow out of matching ground
vec3 meadow(vec2 p) {
	float n1 = texture(noise_big, p / 150.0).r;
	float n2 = texture(noise_big, p / 43.0 + 0.37).r;
	float n3 = texture(noise_fine, p / 9.0).r;
	vec3 c = mix(grass_a, grass_b, smoothstep(0.45, 0.75, n1));
	c = mix(c, grass_c, smoothstep(0.5, 0.85, n2) * 0.55);
	return c * (0.95 + n3 * 0.1);
}

void fragment() {
	vec2 p = wpos.xz;
	vec2 muv = (p + half_size) / (2.0 * half_size);
	vec4 m = texture(world_mask, muv);
	float nf = texture(noise_fine, p / 3.0).r;
	float nb = texture(noise_big, p / 25.0).r;

	vec3 col = meadow(p);
	// the ground under grass is a little darker and earthier than the blades
	col *= 0.8;
	float rough = 0.95;
	vec3 nrm_ts = vec3(0.5, 0.5, 1.0);

	// shore: sand ring, mud below the water line
	float shore = smoothstep(0.05, 0.95, m.a + (nf - 0.5) * 0.5 + (nb - 0.5) * 0.3);
	shore *= smoothstep(water_h + 0.75, water_h + 0.3, wpos.y + (nf - 0.5) * 0.3);   // a narrow sandy band, then grass
	col = mix(col, sand * (0.9 + nf * 0.2), shore * 0.7);
	// damp sand at the water line, then the soft silty bed
	col *= mix(1.0, 0.72, smoothstep(water_h + 0.35, water_h + 0.02, wpos.y) * shore);
	col = mix(col, mix(vec3(0.36, 0.33, 0.22), mud * mix(0.8, 1.1, nb), smoothstep(water_h - 0.1, water_h - 0.9, wpos.y)), smoothstep(water_h + 0.02, water_h - 0.12, wpos.y));

	// rock on steep slopes (triplanar-ish: projected sideways)
	float slope = 1.0 - wnrm.y;
	float rockw = smoothstep(0.28, 0.45, slope + (nb - 0.5) * 0.15);
	vec3 rk = texture(rock_albedo, vec2(p.x + p.y, wpos.y) / 6.0).rgb * vec3(0.95, 0.93, 0.9);
	col = mix(col, rk, rockw);

	// dirt roads: warm packed earth with pebbles, ragged grassy edges
	float edge = m.r + (nf - 0.5) * 0.55 + (nb - 0.5) * 0.25;
	float road = smoothstep(0.35, 0.6, edge);
	vec3 dirt = mix(dirt_a, dirt_b, texture(noise_fine, p / 1.3).r);
	dirt *= 0.88 + 0.24 * smoothstep(0.62, 0.7, texture(noise_fine, p * 1.7).r);  // pebbles catch the light
	col = mix(col, dirt, road);
	rough = mix(rough, 0.9, road);

	// cobbles in town: the village kit's stone texture, 2.6 m per tile
	float cob = smoothstep(0.4, 0.65, m.g + (nf - 0.5) * 0.3) * road;
	vec2 cuv = p / 1.6;
	vec3 cc = texture(cobble_albedo, cuv).rgb;
	col = mix(col, cc * vec3(1.0, 0.97, 0.92), cob);
	nrm_ts = mix(nrm_ts, texture(cobble_normal, cuv).rgb, cob);
	rough = mix(rough, 0.8, cob);

	// soft large-scale light and shade, like a painter's wash
	col *= 0.92 + 0.16 * texture(noise_big, p / 70.0 + 0.61).r;

	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.3;
	NORMAL_MAP = nrm_ts;
}
