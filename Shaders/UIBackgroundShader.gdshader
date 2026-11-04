shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float density : hint_range(0.1, 2.0) = 1.0;
uniform vec4 node_color : source_color = vec4(1.0, 0.38, 0.04, 0.34);
uniform vec4 connection_color : source_color = vec4(0.05, 0.82, 1.0, 0.24);

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float grid_line(float coordinate, float width) {
	float cell = abs(fract(coordinate) - 0.5);
	return smoothstep(width, 0.5, cell);
}

void fragment() {
	vec2 uv = UV;
	float t = (TIME * 0.18 + time * 0.06) * speed;
	vec2 ratio = vec2(32.0, 18.0) * density;
	vec2 moving_grid = uv * ratio + vec2(t * 0.35, t * 0.18);

	float fine = max(grid_line(moving_grid.x, 0.488), grid_line(moving_grid.y, 0.488));
	float major = max(grid_line(moving_grid.x / 4.0, 0.47), grid_line(moving_grid.y / 4.0, 0.47));

	vec3 colour = connection_color.rgb * fine * 0.13;
	colour += connection_color.rgb * major * 0.2;

	// Short circuit traces appear in deterministic cells and move as one layer.
	vec2 cell_id = floor(moving_grid / vec2(4.0, 3.0));
	vec2 local = fract(moving_grid / vec2(4.0, 3.0));
	float seed = hash21(cell_id);
	float horizontal = step(0.88, seed) * step(0.12, local.x) * step(local.x, 0.82)
		* (1.0 - smoothstep(0.02, 0.07, abs(local.y - 0.5)));
	float node = step(0.94, seed) * (1.0 - smoothstep(0.025, 0.07, distance(local, vec2(0.82, 0.5))));
	colour += node_color.rgb * horizontal * 0.36;
	colour += node_color.rgb * node * 0.75;

	// Sparse square data packets reinforce the pixel-art language.
	vec2 pixel_cell = floor(uv * vec2(120.0, 68.0));
	float packet = step(0.996, hash21(pixel_cell + floor(t * 2.0)));
	colour += mix(connection_color.rgb, node_color.rgb, hash21(pixel_cell + 5.0)) * packet * 0.55;

	float scanline = 0.94 + 0.06 * sin(uv.y * 900.0);
	float vignette = 1.0 - smoothstep(0.25, 0.76, distance(uv, vec2(0.5)));
	colour *= scanline * mix(0.45, 1.0, vignette);

	float alpha = clamp(fine * 0.08 + major * 0.16 + horizontal * 0.3 + node * 0.55 + packet * 0.5, 0.0, 0.72);
	COLOR = vec4(colour, alpha);
}
