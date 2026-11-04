shader_type canvas_item;

// Shared arcade backdrop for both game modes. It deliberately stays dark in the
// centre so bullets, pickups and enemies remain readable during dense fights.
uniform vec4 bg_color_dark : source_color = vec4(0.008, 0.012, 0.035, 1.0);
uniform vec4 bg_color_light : source_color = vec4(0.035, 0.055, 0.12, 1.0);
uniform vec4 cyan_glow : source_color = vec4(0.05, 0.82, 1.0, 1.0);
uniform vec4 orange_glow : source_color = vec4(1.0, 0.38, 0.04, 1.0);
uniform float grid_scale : hint_range(10.0, 100.0) = 42.0;
uniform float movement_speed : hint_range(0.0, 2.0) = 0.35;
uniform float brightness : hint_range(0.2, 2.0) = 1.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float line_mask(float coordinate, float width) {
	float cell = abs(fract(coordinate) - 0.5);
	return smoothstep(width, 0.5, cell);
}

void fragment() {
	vec2 uv = UV;
	vec2 centred = uv - vec2(0.5);
	float t = TIME * movement_speed;

	// Deep blue-violet base with a dim horizon glow.
	float vertical = smoothstep(0.0, 1.0, uv.y);
	float mist = value_noise(uv * 5.0 + vec2(t * 0.035, -t * 0.02));
	vec3 colour = mix(bg_color_light.rgb, bg_color_dark.rgb, vertical * 0.72 + 0.12);
	colour += vec3(0.035, 0.02, 0.075) * mist;
	float horizon_axis = (uv.y - 0.43) * 8.0;
	float horizon = exp(-(horizon_axis * horizon_axis));
	colour += mix(cyan_glow.rgb, orange_glow.rgb, uv.x) * horizon * 0.055;

	// Top-down circuitry grid. Two scales give it an arcade floor-board feel.
	vec2 drift = vec2(t * 0.12, t * 0.075);
	vec2 grid_uv = uv * vec2(grid_scale, grid_scale * 0.56) + drift;
	float fine_grid = max(line_mask(grid_uv.x, 0.482), line_mask(grid_uv.y, 0.482));
	vec2 major_uv = grid_uv / 4.0;
	float major_grid = max(line_mask(major_uv.x, 0.47), line_mask(major_uv.y, 0.47));
	colour += cyan_glow.rgb * fine_grid * 0.032;
	colour += cyan_glow.rgb * major_grid * 0.065;

	// Sparse glowing data blocks travel on the grid instead of looking like noise.
	vec2 block_cell = floor(grid_uv / vec2(3.0, 2.0));
	vec2 block_local = fract(grid_uv / vec2(3.0, 2.0));
	float block_seed = hash21(block_cell);
	float block_shape = step(0.965, block_seed) * step(0.16, block_local.x) * step(block_local.x, 0.84)
		* step(0.28, block_local.y) * step(block_local.y, 0.72);
	vec3 block_colour = mix(cyan_glow.rgb, orange_glow.rgb, step(0.5, hash21(block_cell + 7.31)));
	colour += block_colour * block_shape * 0.16;

	// Pixel stars and tiny chain nodes add depth without obscuring gameplay.
	vec2 star_grid = floor(uv * vec2(180.0, 100.0));
	float star = step(0.9935, hash21(star_grid));
	float twinkle = 0.55 + 0.45 * sin(t * 2.0 + hash21(star_grid + 3.0) * 6.28318);
	colour += mix(cyan_glow.rgb, orange_glow.rgb, hash21(star_grid + 11.0)) * star * twinkle * 0.22;

	// CRT finish and central readability vignette.
	float scanline = 0.965 + 0.035 * sin(uv.y * 900.0);
	float vignette = 1.0 - smoothstep(0.28, 0.78, length(centred));
	colour *= scanline * mix(0.62, 1.0, vignette);

	COLOR = vec4(colour * brightness, 1.0);
}
