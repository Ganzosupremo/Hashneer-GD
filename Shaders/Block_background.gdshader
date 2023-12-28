shader_type canvas_item;

uniform sampler2D iChannel1;
uniform sampler2D iChannel0;
uniform vec4 color: source_color;

float text(vec2 fragCoord, vec2 texture_pixel_size)
{
    vec2 uv = mod(fragCoord.xy, 16.0) * 0.0625;
    vec2 block = fragCoord * 0.0625 - uv;
    uv = uv * 0.8 + 0.1; // scale the letters up a bit
    uv += floor(texture(iChannel1, block / (1.0 / texture_pixel_size.y) + TIME * 0.002).xy * 16.0); // randomize letters
    uv *= 0.0625; // bring back into 0-1 range
    uv.x = -uv.x; // flip letters horizontally
    return texture(iChannel0, uv).r;
}

vec3 rain(vec2 fragCoord, vec2 screen_pixel_size) {
	fragCoord.x -= mod(fragCoord.x, 16);
	
	float offset = sin(fragCoord.x * 16.0);
	float speed = cos(fragCoord.x * 3.0) * 0.3;
	float y = fract(fragCoord.y / (1.0 / screen_pixel_size.y) + TIME * speed * offset);
	
	return vec3(0.1, 1.0,0.35) / (y * 20.0);
}

void fragment() {
	COLOR = vec4(text(FRAGCOORD.xy, TEXTURE_PIXEL_SIZE) * rain(FRAGCOORD.xy, SCREEN_PIXEL_SIZE), 1.0) * color;
}
