// Meadow grass, placed entirely on the GPU: each instance finds its own spot from its number,
// sits on the ground (height map), takes the ground's colour, sways in gusting wind and bends
// away from the hero's feet. Clumps thin out with distance so the far meadow costs little.
shader_type spatial;
render_mode cull_disabled, skip_vertex_transform, diffuse_burley;

uniform sampler2D height_map : filter_linear, repeat_disable;
uniform sampler2D world_mask : filter_linear, repeat_disable;
uniform sampler2D clear_mask : filter_linear, repeat_disable;   // 1 where nothing may grow (houses, rocks)
uniform sampler2D noise_big : filter_linear_mipmap, repeat_enable;
uniform sampler2D noise_fine : filter_linear_mipmap, repeat_enable;
uniform float half_size = 128.0;
uniform float water_h = 0.35;
uniform float spacing = 0.2;
uniform int per_row = 80;
uniform float clump_scale = 1.0;
uniform float fade_near = 30.0;
uniform float fade_far = 45.0;
global uniform float wind_time;
uniform float night = 0.0;
global uniform vec3 hero_pos;
uniform vec3 grass_a : source_color = vec3(0.38, 0.56, 0.20);
uniform vec3 grass_b : source_color = vec3(0.60, 0.64, 0.28);
uniform vec3 grass_c : source_color = vec3(0.27, 0.45, 0.18);
uniform vec3 tip_tint : source_color = vec3(1.0, 0.95, 0.6);

varying float v_h;
varying vec3 v_col;
varying float v_rand;
varying float v_gust;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

vec3 meadow(vec2 p) {
	float n1 = texture(noise_big, p / 150.0).r;
	float n2 = texture(noise_big, p / 43.0 + 0.37).r;
	float n3 = texture(noise_fine, p / 9.0).r;
	vec3 c = mix(grass_a, grass_b, smoothstep(0.45, 0.75, n1));
	c = mix(c, grass_c, smoothstep(0.5, 0.85, n2) * 0.55);
	return c * (0.95 + n3 * 0.1);
}

void vertex() {
	int id = INSTANCE_ID;
	vec2 cell = vec2(float(id % per_row), float(id / per_row));
	vec2 origin = NODE_POSITION_WORLD.xz;
	float r1 = hash(cell + origin * 0.013);
	float r2 = hash(cell.yx * 1.37 + origin * 0.021 + 3.1);
	vec2 wp = origin + (cell + vec2(r1, r2)) * spacing;
	vec2 uv = (wp + half_size) / (2.0 * half_size);
	float ground = texture(height_map, uv).r;
	vec4 m = texture(world_mask, uv);
	float clr = texture(clear_mask, uv).r;
	float dist = distance(wp, CAMERA_POSITION_WORLD.xz);
	// how much grass grows here: none on roads, in water, under buildings; shorter at the edges
	float n = texture(noise_big, wp / 31.0).r;
	float grow = (1.0 - smoothstep(0.1, 0.5, m.r)) * smoothstep(water_h + 0.3, water_h + 0.55, ground) * (1.0 - clr);
	float keep = step(r1 * 0.999, 1.0 - smoothstep(fade_near, fade_far, dist));
	float s = clump_scale * grow * keep * (0.75 + 0.5 * hash(cell * 2.3 + origin));
	s *= mix(0.8, 1.25, smoothstep(0.3, 0.8, n));       // a little taller in the lush drifts
	float ang = hash(cell + 7.7) * 6.2831;
	mat2 rot = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang)));
	vec3 v = VERTEX;
	v.xz = rot * v.xz;
	float h = UV.y;                                        // 0 root .. 1 tip
	v.xz *= s;
	v.y *= s * mix(0.85, 1.15, hash(cell * 3.7));
	// wind: broad gusts roll across the meadow, plus a light flutter
	vec2 wdir = normalize(vec2(1.0, 0.35));
	float gust = texture(noise_big, wp / 38.0 - wdir * wind_time * 0.035).r;
	float g = smoothstep(0.3, 0.9, gust);
	float sway = (0.08 + g * 0.3) + sin(wind_time * 2.1 + wp.x * 0.8 + wp.y * 0.6) * 0.04;
	v.xz += wdir * sway * h * h * s;
	v.y -= g * 0.12 * h * h * s;
	// the hero parts the grass
	vec3 wv = vec3(wp.x, ground, wp.y) + v;
	vec2 away = wv.xz - hero_pos.xz;
	float push = (1.0 - smoothstep(0.25, 0.9, length(away))) * step(abs(wv.y - hero_pos.y), 1.5);
	v.xz += normalize(away + 0.0001) * push * 0.35 * h * s;
	v.y -= push * 0.18 * h * s;
	wv = vec3(wp.x, ground, wp.y) + v;
	VERTEX = (VIEW_MATRIX * vec4(wv, 1.0)).xyz;
	// grass is lit like the ground it grows from: one soft surface, not a thousand shiny spikes
	float px = 1.0 / (2.0 * half_size);
	vec3 gn = normalize(vec3(texture(height_map, uv - vec2(px, 0.0)).r - texture(height_map, uv + vec2(px, 0.0)).r, 2.0, texture(height_map, uv - vec2(0.0, px)).r - texture(height_map, uv + vec2(0.0, px)).r));
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(gn + vec3(rot * NORMAL.xz, 0.0).xzy * 0.12), 0.0)).xyz);
	v_h = h;
	v_rand = hash(cell * 5.1 + origin);
	v_col = meadow(wp) * (0.94 + 0.12 * v_rand);
	v_gust = g;
}

void fragment() {
	// roots match the ground beneath; tips are lighter and warmer; gusts brighten as they pass
	vec3 root = v_col * 0.8;
	vec3 tip = v_col * mix(vec3(1.0), tip_tint, 0.35) * 1.18;
	vec3 col = mix(root, tip, smoothstep(0.0, 1.0, v_h));
	col *= 1.0 + v_gust * 0.12 * v_h;
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
	BACKLIGHT = vec3(0.5, 0.55, 0.2) * v_h * v_h;
	AO = mix(0.75, 1.0, v_h);
	AO_LIGHT_AFFECT = 0.25;
}
