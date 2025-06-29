shader_type canvas_item;

uniform sampler2D noise_texture;
uniform float shield_strength = 1.0;
uniform float hit_effect : hint_range(0, 1) = 0.0;

void fragment() {
    // Base shield color
    vec3 shield_color = mix(vec3(0.2, 0.5, 1.0), vec3(1.0), hit_effect);

    // Noise pattern for energy effect
    float noise = texture(noise_texture, UV * 5.0 + TIME * 0.5).r;
    noise = smoothstep(0.3, 0.7, noise);

    // Edge glow effect
    float edge = smoothstep(0.9, 1.0, 1.0 - UV.y) * shield_strength;

    // Combine effects
    float alpha = mix(noise, 1.0, edge) * shield_strength;
    alpha = clamp(alpha, 0.0, 1.0);

    // Apply to output
    COLOR = vec4(shield_color, alpha * 0.7);
}