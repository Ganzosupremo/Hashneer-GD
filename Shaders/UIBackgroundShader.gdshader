shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float density : hint_range(0.1, 2.0) = 1.0;
uniform vec4 node_color : source_color = vec4(1.0, 0.6, 0.0, 0.3);
uniform vec4 connection_color : source_color = vec4(0.2, 0.5, 1.0, 0.2);

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
    vec2 screen_uv = uv * 8.0 * density;
    
    float t = time * speed * 0.1;
    
    // Network nodes
    float nodes = 0.0;
    for(int i = 0; i < 20; i++) {
        vec2 pos = vec2(hash(vec2(float(i), 0.0)), hash(vec2(float(i), 1.0)));
        pos += sin(t + float(i)) * 0.1;
        
        float dist = distance(uv, pos);
        nodes += smoothstep(0.05, 0.0, dist) * 0.8;
    }
    
    // Connection lines
    float connections = 0.0;
    float grid = noise(screen_uv + t * 0.5) * 0.5;
    connections += smoothstep(0.7, 0.9, grid) * 0.3;
    
    // Floating particles
    float particles = noise(screen_uv * 2.0 + t) * noise(screen_uv * 3.0 - t * 0.7);
    particles = smoothstep(0.6, 0.8, particles) * 0.2;
    
    vec4 node_contribution = node_color * nodes;
    vec4 connection_contribution = connection_color * connections;
    vec4 particle_contribution = vec4(1.0, 0.8, 0.4, 1.0) * particles * 0.5;
    
    COLOR = node_contribution + connection_contribution + particle_contribution;
    COLOR.a *= smoothstep(0.0, 0.2, distance(uv, vec2(0.5))) * 0.8 + 0.2;
}
