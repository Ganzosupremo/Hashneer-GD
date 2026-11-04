shader_type canvas_item;

uniform vec4 cyan : source_color = vec4(0.05, 0.85, 1.0, 1.0);
uniform vec4 orange : source_color = vec4(1.0, 0.36, 0.04, 1.0);
uniform vec4 dark_fill : source_color = vec4(0.015, 0.025, 0.06, 1.0);
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.2;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float pulse = 0.84 + 0.16 * sin(TIME * pulse_speed + UV.x * 18.0 + UV.y * 10.0);
	float accent = smoothstep(0.72, 1.0, fract(UV.x * 8.0 + UV.y * 3.0));
	vec3 neon = mix(cyan.rgb, orange.rgb, accent * 0.3);
	vec3 final_colour = mix(dark_fill.rgb, neon * pulse, smoothstep(0.08, 0.82, luminance));
	COLOR = vec4(final_colour, source.a * COLOR.a);
}
