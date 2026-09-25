// A storybook sky: soft blue days, honey sunsets, deep blue nights with stars and a moon,
// and slow drifting clouds lit by the sun. Driven by DayNight (sun = light 0, moon = light 1).
shader_type sky;
render_mode use_half_res_pass;

uniform vec3 day_zenith : source_color = vec3(0.24, 0.47, 0.82);
uniform vec3 day_horizon : source_color = vec3(0.70, 0.83, 0.93);
uniform vec3 dusk_zenith : source_color = vec3(0.20, 0.25, 0.48);
uniform vec3 dusk_horizon : source_color = vec3(0.98, 0.62, 0.35);
uniform vec3 night_zenith : source_color = vec3(0.012, 0.02, 0.06);
uniform vec3 night_horizon : source_color = vec3(0.04, 0.07, 0.14);
uniform vec3 ground_col : source_color = vec3(0.16, 0.2, 0.14);
uniform sampler2D cloud_noise : filter_linear_mipmap, repeat_enable;
uniform float cloud_cover = 0.5;
uniform float day = 1.0;        // 1 full day, 0 night
uniform float dusk = 0.0;       // 1 at sunrise/sunset
uniform float time_s = 0.0;     // game seconds, drives cloud drift

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void sky() {
	vec3 d = EYEDIR;
	float up = clamp(d.y, -1.0, 1.0);
	float h = pow(1.0 - max(up, 0.0), 3.0);

	vec3 zen = mix(night_zenith, day_zenith, day); zen = mix(zen, dusk_zenith, dusk * 0.6);
	vec3 hor = mix(night_horizon, day_horizon, day); hor = mix(hor, dusk_horizon, dusk);
	vec3 col = mix(zen, hor, h);

	// sunset glow is strongest toward the sun
	vec3 sd = LIGHT0_DIRECTION;
	float to_sun = max(dot(d, sd), 0.0);
	col += dusk_horizon * pow(to_sun, 6.0) * dusk * 0.7 * h;
	// sun disc and halo
	if (LIGHT0_ENABLED) {
		col += LIGHT0_COLOR * (pow(to_sun, 900.0) * 30.0 + pow(to_sun, 60.0) * 0.35) * clamp(sd.y * 6.0 + 0.4, 0.0, 1.0);
	}
	// moon
	if (LIGHT1_ENABLED) {
		float to_moon = max(dot(d, LIGHT1_DIRECTION), 0.0);
		col += vec3(0.85, 0.9, 1.0) * (smoothstep(0.99955, 0.9997, to_moon) * 2.2 + pow(to_moon, 80.0) * 0.12) * (1.0 - day);
	}
	// stars
	if (up > 0.0) {
		vec2 sp = d.xz / (d.y + 0.35) * 220.0;
		vec2 cell = floor(sp);
		float s = hash(cell);
		float star = step(0.994, s) * smoothstep(0.5, 0.0, length(fract(sp) - 0.5)) * (0.6 + 0.4 * sin(time_s * 0.02 + s * 80.0));
		col += vec3(0.9, 0.93, 1.0) * star * (1.0 - day) * (1.0 - dusk) * smoothstep(0.0, 0.25, up);
	}
	// clouds: a flat layer projected over the dome
	if (up > 0.01) {
		vec2 cuv = d.xz / (d.y + 0.08) * 0.35 + vec2(time_s * 0.0009, time_s * 0.0003);
		float n = texture(cloud_noise, cuv).r * 0.62 + texture(cloud_noise, cuv * 2.7 + 0.3).r * 0.28 + texture(cloud_noise, cuv * 7.1).r * 0.1;
		float c = smoothstep(1.0 - cloud_cover, 1.0 - cloud_cover + 0.28, n) * smoothstep(0.01, 0.2, up);
		float lit = 0.6 + 0.4 * smoothstep(-0.3, 1.0, dot(normalize(vec3(d.x, 0.2, d.z)), sd));
		vec3 cday = vec3(1.0, 0.99, 0.97) * lit;
		vec3 cdusk = mix(vec3(0.55, 0.42, 0.5), vec3(1.0, 0.68, 0.45), lit);
		vec3 cnight = vec3(0.06, 0.08, 0.13);
		vec3 cc = mix(cnight, cday, day); cc = mix(cc, cdusk, dusk * 0.85);
		col = mix(col, cc, c * 0.92);
	}
	// below the horizon: fade into the land
	col = mix(col, mix(ground_col * (0.15 + 0.85 * day), hor * 0.6, 0.5), smoothstep(0.0, -0.08, up));
	COLOR = col;
}
