shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform sampler2D first_noise : repeat_enable;
uniform sampler2D second_noise : repeat_enable;

uniform vec2 scroll_horizontal = vec2(0.05,0.05);
uniform vec2 scroll_vertical = vec2(-0.05, -0.05);

uniform vec4 tone_color : source_color;
uniform vec4 top_color : source_color;
uniform float light_start : hint_range(0.0, 1.0) = 0.275;
uniform float light_end : hint_range(0.0, 1.0) = 0.4;


uniform float distorsion_strength : hint_range(-1.0, 1.0) = 0.2;

void fragment() {
	float depth = texture(first_noise, UV + scroll_horizontal * TIME).r 
		* texture(second_noise, UV + scroll_vertical * TIME).r;

	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV + distorsion_strength * vec2(depth));
	vec4 top_light = smoothstep(light_start, light_end, depth) * top_color;
	
	COLOR = screen_color * tone_color * top_light;
}
