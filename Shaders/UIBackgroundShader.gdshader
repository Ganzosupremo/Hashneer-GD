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

// Generate hexadecimal-like pattern for hash effect
float hexPattern(vec2 p) {
    vec2 cell = floor(p);
    float h = hash(cell);
    // Create blocky pattern like hex characters
    vec2 local = fract(p);
    float pattern = step(0.3, h) * step(local.x, 0.8) * step(local.y, 0.8);
    return pattern;
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

    // Connection lines with slight blue tint
    float connections = 0.0;
    float grid = noise(screen_uv + t * 0.5) * 0.5;
    connections += smoothstep(0.7, 0.9, grid) * 0.3;

    // Floating particles

    // Falling "hash" effect - multiple columns of descending blocks
    float falling_hashes = 0.0;
    for(int col = 0; col < 12; col++) {
        float col_x = float(col) * 0.09 + hash(vec2(float(col), 0.0)) * 0.02;
        float col_speed = 0.3 + hash(vec2(float(col), 1.0)) * 0.4;
        float col_offset = hash(vec2(float(col), 2.0)) * 6.28;

        // Create falling effect
        vec2 hash_uv = vec2(uv.x, uv.y + t * col_speed + col_offset);
        hash_uv.x = (hash_uv.x - col_x) * 15.0; // Narrow columns
        hash_uv.y *= 20.0; // Stretched vertically

        float hash_blocks = hexPattern(hash_uv);
        // Add glow to the hash blocks
        float hash_glow = hash_blocks * smoothstep(1.2, 0.0, abs(hash_uv.x));
        falling_hashes += hash_glow * 0.15;
    }

    // Floating particles (smaller contribution)
    float particles = noise(screen_uv * 2.0 + t) * noise(screen_uv * 3.0 - t * 0.7);
    particles = smoothstep(0.6, 0.8, particles) * 0.2;

    particles = smoothstep(0.6, 0.8, particles) * 0.15;

    // Bitcoin-themed gold/orange glow
    vec4 bitcoin_gold = vec4(1.0, 0.65, 0.0, 1.0);
    vec4 chain_blue = vec4(0.2, 0.6, 1.0, 1.0);

    vec4 node_contribution = node_color * nodes;
    vec4 connection_contribution = connection_color * connections;
    vec4 particle_contribution = vec4(1.0, 0.8, 0.4, 1.0) * particles * 0.5;

    COLOR = node_contribution + connection_contribution + particle_contribution;
    vec4 particle_contribution = bitcoin_gold * particles;
    vec4 hash_contribution = bitcoin_gold * falling_hashes * 0.8;

    COLOR = node_contribution + connection_contribution + particle_contribution + hash_contribution;

    // Add subtle pulsing to create "blockchain" feel
    float pulse = sin(t * 2.0) * 0.05 + 0.95;
    COLOR.rgb *= pulse;

    // Vignette effect
    COLOR.a *= smoothstep(0.0, 0.2, distance(uv, vec2(0.5))) * 0.8 + 0.2;
}