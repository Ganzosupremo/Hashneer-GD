shader_type canvas_item;

uniform vec4 bg_color: source_color;
uniform float size:hint_range(10.0, 150.0) = 100.0;
uniform float prob:hint_range(0.01, 1.2) = 0.9;

float rand(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	vec2 pos = floor(1.0 / size * FRAGCOORD.xy);
	float color = 0.0;
	float starValue = rand(pos);

	if (starValue > prob)
	{
		vec2 center = size * pos + vec2(size, size) * 0.8;
		float t = 0.9 + 0.2 * sin(TIME * 4.0 + (starValue - prob) / (1.0 - prob) * 45.0);
		color = 1.0 - distance(FRAGCOORD.xy, center) / (0.5 * size);
		color = color * t / (abs(FRAGCOORD.y - center.y)) * t / (abs(FRAGCOORD.x - center.x));
	}
	else if (rand(SCREEN_UV.xy / 20.0) > 0.996)
	{
		float r = rand(SCREEN_UV.xy);
		color = r * (0.85 * sin(TIME * (r * 5.0) + 720.0 * r) + 0.95);
	}

//	vec4 speed = texture(bg_color, 2.0 * TIME);
//
	COLOR = vec4(vec3(color),1.0) + bg_color;
}