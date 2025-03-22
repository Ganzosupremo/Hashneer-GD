shader_type canvas_item;
//render_mode shadows_disabled, specular_disabled, ambient_light_disabled, unshaded;

uniform vec2 iResolution = vec2(1920, 1080);

//
// Exposed parameters
//
uniform float Scroll = 0.0125;
uniform float Depth = 0.25;
uniform float Rotation = -0.7854;
uniform float Contrast = 0.2;
uniform float NoiseSpeed = 1.0;
uniform float PatternScale = 11.0; // Used in TriangleUV() calls

uniform vec4 BackgroundColor : source_color = vec4(0.07451, 0.09022, 0.2471, 1.0); // Background color
uniform vec4 ForegroundColor : source_color = vec4(0.1804, 0.1922, 0.4942, 1.0);   // Foreground color

//
// Perlin3D from https://github.com/BrianSharpe/Wombat/blob/master/Perlin3D.glsl
//
float Perlin3D(vec3 P) {
    // establish our grid cell and unit position
    vec3 Pi = floor(P);
    vec3 Pf = P - Pi;
    vec3 Pf_min1 = Pf - 1.0;

    // clamp the domain
    Pi = Pi - floor(Pi * (1.0 / 69.0)) * 69.0;
    vec3 Pi_inc1 = step(Pi, vec3(69.0 - 1.5)) * (Pi + 1.0);

    // calculate the hash
    vec4 Pt = vec4(Pi.xy, Pi_inc1.xy) + vec2(50.0, 161.0).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    const vec3 SOMELARGEFLOATS = vec3(635.298681, 682.357502, 668.926525);
    const vec3 ZINC = vec3(48.500388, 65.294118, 63.934599);
    vec3 lowz_mod = vec3(1.0 / (SOMELARGEFLOATS + Pi.zzz * ZINC));
    vec3 highz_mod = vec3(1.0 / (SOMELARGEFLOATS + Pi_inc1.zzz * ZINC));
    vec4 hashx0 = fract(Pt * lowz_mod.xxxx);
    vec4 hashx1 = fract(Pt * highz_mod.xxxx);
    vec4 hashy0 = fract(Pt * lowz_mod.yyyy);
    vec4 hashy1 = fract(Pt * highz_mod.yyyy);
    vec4 hashz0 = fract(Pt * lowz_mod.zzzz);
    vec4 hashz1 = fract(Pt * highz_mod.zzzz);

    // calculate the gradients
    vec4 grad_x0 = hashx0 - 0.49999;
    vec4 grad_y0 = hashy0 - 0.49999;
    vec4 grad_z0 = hashz0 - 0.49999;
    vec4 grad_x1 = hashx1 - 0.49999;
    vec4 grad_y1 = hashy1 - 0.49999;
    vec4 grad_z1 = hashz1 - 0.49999;
    
    vec4 grad_results_0 = inversesqrt(grad_x0 * grad_x0 + grad_y0 * grad_y0 + grad_z0 * grad_z0) *
        (vec2(Pf.x, Pf_min1.x).xyxy * grad_x0 +
         vec2(Pf.y, Pf_min1.y).xxyy * grad_y0 +
         Pf.zzzz * grad_z0);
         
    vec4 grad_results_1 = inversesqrt(grad_x1 * grad_x1 + grad_y1 * grad_y1 + grad_z1 * grad_z1) *
        (vec2(Pf.x, Pf_min1.x).xyxy * grad_x1 +
         vec2(Pf.y, Pf_min1.y).xxyy * grad_y1 +
         Pf_min1.zzzz * grad_z1);

    // Classic Perlin Interpolation
    vec3 blend = Pf * Pf * Pf * (Pf * (Pf * 6.0 - 15.0) + 10.0);
    vec4 res0 = mix(grad_results_0, grad_results_1, blend.z);
    vec4 blend2 = vec4(blend.xy, vec2(1.0 - blend.xy));
    float final = dot(res0, blend2.zxzx * blend2.wwyy);
    return final * 1.1547005383792515290182975610039; // scale to strict -1.0 -> 1.0
}

vec2 rotate2(vec2 xy, float r) {
    vec2 ab;
    ab.x = xy.x * cos(r) - xy.y * sin(r);
    ab.y = xy.y * cos(r) + xy.x * sin(r);
    return ab;
}

float Screen(float a, float b) {
    return 1.0 - ((1.0 - a) * (1.0 - b));
}

vec2 Rotate(vec2 xy, float angle) {
    return vec2(xy.x * cos(angle) - xy.y * sin(angle),
                xy.x * sin(angle) + xy.y * cos(angle));
}

vec2 Triangle(vec2 uv, float c) {
    float r = 0.5235988;
    vec2 o = uv;
    o.x = floor(uv.x * c + 0.5);
    o.y = mix(floor(Rotate(uv * c + 0.5, r).y), floor(Rotate(uv * c + 0.5, -r).y), 0.5);
    // Adjust vertical scaling to keep range consistent.
    o.y *= 1.154700555;
    return o / c;
}

vec2 TriangleUV(vec2 uv, float c, float r, float s) {
    uv = Rotate(uv, r);
    // Apply vertical scroll offset.
    uv.y += s;
    uv = Triangle(uv, c);
    // Invert the vertical scroll so pattern remains static.
    uv.y -= s;
    uv = Rotate(uv, -r);
    uv += 0.5;
    return uv;
}

void fragment() {
    // Compute fragment coordinate in pixels.
    vec2 fragCoord = UV * iResolution;
    
    // Process UV map for texture pattern mapping.
    vec2 uv = fragCoord.xy * 0.00025;
    
    // Compute two Perlin noise contributions.
    float n1 = Perlin3D(vec3(TriangleUV(uv, PatternScale, Rotation, TIME * Scroll) * 10.0, TIME * NoiseSpeed));
    float n2 = Perlin3D(vec3(TriangleUV(uv * 2.0 + vec2(10.0, 10.0), PatternScale, Rotation, TIME * Scroll) * 10.0, TIME * NoiseSpeed));
    
    // Combine and clamp noise values.
    n1 = clamp((n1 + n2) * 0.5 + 0.5, 0.0, 1.0);
    
    // Mix the two colors based on the noise value.
    COLOR = mix(BackgroundColor
, ForegroundColor, n1);
}