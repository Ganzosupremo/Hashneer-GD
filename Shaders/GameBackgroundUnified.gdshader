shader_type canvas_item;

uniform float time = 0.0;
uniform vec4 bg_color_dark : source_color = vec4(0.03, 0.04, 0.08, 1.0);
uniform vec4 bg_color_light : source_color = vec4(0.06, 0.08, 0.14, 1.0);
uniform float grid_scale : hint_range(10.0, 100.0) = 40.0;
uniform float movement_speed : hint_range(0.0, 2.0) = 0.3;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec2 uv = UV;
    
    // Slowly moving coordinates
    vec2 moving_uv = uv + vec2(time * movement_speed * 0.05, time * movement_speed * 0.03);
    
    // Create subtle grid pattern
    vec2 grid_uv = moving_uv * grid_scale;
    vec2 grid_id = floor(grid_uv);
    vec2 grid_local = fract(grid_uv);
    
    // Subtle grid lines
    float grid_lines = 0.0;
    float line_width = 0.02;
    grid_lines += smoothstep(line_width, 0.0, grid_local.x);
    grid_lines += smoothstep(line_width, 0.0, grid_local.y);
    grid_lines *= 0.08; // Very subtle
    
    // Multi-octave noise for variation
    float n = 0.0;
    n += noise(moving_uv * 2.0) * 0.5;
    n += noise(moving_uv * 4.0) * 0.25;
    n += noise(moving_uv * 8.0) * 0.125;
    n /= 0.875; // Normalize
    
    // Mix colors based on noise
    vec4 base_color = mix(bg_color_dark, bg_color_light, n);
    
    // Add grid contribution
    base_color.rgb += vec3(grid_lines);
    
    // Subtle vignette to focus attention on center
    float vignette = 1.0 - smoothstep(0.4, 1.2, distance(uv, vec2(0.5)));
    vignette = vignette * 0.15 + 0.85; // Very subtle
    
    COLOR = base_color;
    COLOR.rgb *= vignette;
}
