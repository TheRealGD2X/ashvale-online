// Trees, bushes, flowers and plants from the nature kit, moving in the same wind as the grass:
// whole crowns lean with the gusts, leaves flutter, trunks stay rooted. Leaves let sunlight through.
shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_big : filter_linear_mipmap, repeat_enable;
uniform bool has_normal = false;
uniform bool is_leaf = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 recolor : source_color = vec4(0.0);   // a > 0: repaint (keeps the texture's light and shade)
uniform float alpha_cut = 0.45;
uniform float height_ref = 6.0;      // model height: sway grows with height above the root
uniform float sway = 0.25;           // metres of lean at the top in a full gust
uniform float flutter = 0.03;
global uniform float wind_time;
global uniform vec3 hero_pos;
uniform bool fade_near_hero = false;   // trees go see-through where they hide the hero from the camera
uniform float roughness = 0.85;

varying float v_rand;
varying vec3 v_wpos;

void vertex() {
	vec3 root = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float scale = length(MODEL_MATRIX[1].xyz);
	float h = clamp(VERTEX.y / height_ref, 0.0, 1.5);
	vec2 wdir = normalize(vec2(1.0, 0.35));
	float gust = texture(noise_big, root.xz / 38.0 - wdir * wind_time * 0.035).r * 1.25 - 0.3;
	float bend = gust * sway * h * h * scale + sin(wind_time * 1.3 + root.x * 0.2) * 0.04 * h * scale;
	vec3 disp = vec3(wdir.x, 0.0, wdir.y) * bend;
	disp.y = -abs(bend) * 0.15 * h;
	if (is_leaf) {
		float f = sin(wind_time * 7.0 + wp.x * 3.1 + wp.y * 2.3 + wp.z * 2.7);
		disp += vec3(f, f * 0.6, -f * 0.8) * flutter * (0.4 + gust) * h;
	}
	// displacement is in world space; bring it back into the model's space
	VERTEX += (inverse(mat3(MODEL_MATRIX)) * disp);
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_rand = fract(sin(dot(root.xz, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	if (fade_near_hero && !IN_SHADOW_PASS) {
		vec3 cam = CAMERA_POSITION_WORLD; vec3 hp = hero_pos + vec3(0.0, 1.0, 0.0);
		vec3 ch = hp - cam;
		float t = clamp(dot(v_wpos - cam, ch) / dot(ch, ch), 0.0, 1.0);
		float d = distance(v_wpos, cam + ch * t);
		float keep = smoothstep(1.4, 3.2, d) + step(0.985, t);
		float ign = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
		if (keep < 1.0 && ign > keep * 0.85 + 0.12) discard;
	}
	vec4 c = texture(albedo_tex, UV);
	vec3 col = c.rgb * tint.rgb;
	if (recolor.a > 0.0) col = recolor.rgb * (dot(c.rgb, vec3(0.3, 0.59, 0.11)) * 2.4);
	col *= 0.92 + 0.16 * v_rand;
	if (is_leaf) {
		if (c.a < alpha_cut) discard;
		BACKLIGHT = col * 0.55;
		// leaves facing away from the viewer are a touch darker: gives crowns volume
		col *= FRONT_FACING ? 1.0 : 0.8;
	}
	ALBEDO = col;
	ROUGHNESS = roughness;
	SPECULAR = 0.25;
	if (has_normal) NORMAL_MAP = texture(normal_tex, UV).rgb;
}
