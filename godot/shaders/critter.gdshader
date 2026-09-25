// Butterflies (day) and fireflies (night) for the ambient swarms in src/world/life.gd.
// Butterflies: two painted wings that flap; fireflies: a soft glowing mote that pulses.
shader_type spatial;
render_mode cull_disabled, unshaded, depth_draw_opaque;

uniform bool glow = false;
varying vec4 v_col;
varying float v_seed;

void vertex() {
	v_seed = fract(float(INSTANCE_ID) * 0.6180339);
	float flap = abs(sin(TIME * (14.0 + v_seed * 8.0) + v_seed * 20.0));
	if (!glow) VERTEX.x *= mix(0.25, 1.0, flap);
	// face the camera
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	v_col = COLOR;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	if (glow) {
		float d = length(uv);
		float a = smoothstep(1.0, 0.0, d);
		float pulse = 0.55 + 0.45 * sin(TIME * (2.0 + v_seed * 3.0) + v_seed * 30.0);
		ALBEDO = vec3(1.0, 0.92, 0.5);
		EMISSION = vec3(1.0, 0.85, 0.35) * 6.0 * pulse * a;
		ALPHA = a * a * v_col.a * pulse;
	} else {
		// two wings: upper and lower lobes each side of a thin body
		vec2 p = vec2(abs(uv.x), uv.y);
		float up = length((p - vec2(0.45, 0.25)) / vec2(0.5, 0.55));
		float lo = length((p - vec2(0.35, -0.35)) / vec2(0.35, 0.4));
		float wing = step(min(up, lo), 1.0) * step(0.06, p.x);
		float body = step(p.x, 0.06) * step(abs(uv.y), 0.55);
		if (wing + body < 0.5) discard;
		vec3 c = mix(v_col.rgb, v_col.rgb * 0.35, smoothstep(0.7, 1.0, min(up, lo)));   // dark wing edges
		c = mix(c, vec3(0.15, 0.1, 0.08), body);
		ALBEDO = c;
		ALPHA = v_col.a;
	}
}
