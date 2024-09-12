shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;

uniform float screen_resolution = 1;
uniform vec3 ringColor: source_color;
uniform vec3 ringOuterColor: source_color;

mat2 rot_dist(float s, float d)
{
    float angularspeed = s * pow(d, 8.0);
    float cas = cos(angularspeed);
    float sas = sin(angularspeed);
    return mat2(vec2(cas, -sas), vec2(sas, cas));
}

#define iterations 18
#define formuparam 0.69
#define volsteps 15
#define stepsize 0.010
#define zoom   0.800
#define tile   0.850
#define speed_kali  0.01
#define brightness 0.003
#define darkmatter 0.800
#define distfading 0.800
#define saturation 0.390

vec3 kali_stars(vec3 from, vec3 dir){
	//volumetric rendering
	float s=0.1,fade=1.;
	vec3 v=vec3(0.);
	for (int r=0; r<volsteps; r++) {
		vec3 p=from+s*dir*.5;
		p = abs(vec3(tile)-mod(p,vec3(tile*2.))); // tiling fold
		float pa,a=pa=0.;
		for (int i=0; i<iterations; i++) {
			p=abs(p)/dot(p,p)-formuparam; // the magic formula
			a+=abs(length(p)-pa); // absolute sum of average change
			pa=length(p);
		}
		float dm=max(0.,darkmatter-a*a*.001); //dark matter
		a*=a*a; // add contrast
		if (r>6) fade*=1.-dm; // dark matter, don't render near
		//v+=vec3(dm,dm*.5,0.);
		v+=fade;
		v+=vec3(s,s*s,s*s*s*s)*a*brightness*fade; // coloring based on distance
		fade*=distfading; // distance fading
		s+=stepsize;
	}
    return mix(vec3(length(v)),v,saturation)*.01;
}

void fragment()
{
	vec2 uv = FRAGCOORD.xy/(1.0 / SCREEN_PIXEL_SIZE);
    float ratio = (1.0 / SCREEN_PIXEL_SIZE).y/(1.0 / SCREEN_PIXEL_SIZE).x;
    uv.y *= ratio;

	 vec2 center = ((1.0 / SCREEN_PIXEL_SIZE).xy * .5f) / (1.0 / SCREEN_PIXEL_SIZE).xy;
    center.y *= ratio;

	  float _dist = distance(uv, center);
    float _s = .15;
    float _a = .005;
    vec2 uvp = uv + min(texture(iChannel2, _s * vec2(uv.x + TIME * .1, uv.y + TIME * -.3)).r,
                        texture(iChannel2, _s * vec2(uv.x + TIME * -.3, uv.y + TIME * .2)).r) * _a * pow(1. - _dist, 5.);

	float dist = distance(uvp, center);
    float idist = 1.0 - dist;
    vec2 dir = normalize(uv - center);

    // Mask
    float m = step(.06, dist);
    m *= smoothstep(.065, .08, dist);
    m = (1.0 - dist * 1.6) * 2. * m;
	float mask = m;

	// Phases
    float speed = -0.06;
    float phase1 = fract(TIME * speed + .5);
    float phase2 = fract(TIME * speed);

    float pidist = pow(idist, 2.3);
    vec2 uv1 = (dir * pidist * .2) + phase1 * dir;
    vec2 uv2 = (dir * pidist * .2) + phase2 * dir;

    // Samplings
    float lerp = abs((.5 - phase1) / .5);
    float sampling1 = texture(iChannel0, uv1 * rot_dist(2.4, idist)).r;
    float sampling2 = texture(iChannel0, uv2 * rot_dist(2.4, idist)).r;

 	float sampling3 = texture(iChannel0, uv1 * 2. * rot_dist(2.6, idist)).g;
    float sampling4 = texture(iChannel0, uv2 * 2. * rot_dist(2.6, idist)).g;

    float sampling5 = texture(iChannel1, uv1 * rot_dist(4.6, idist) * .4).r;
    float sampling6 = texture(iChannel1, uv2 * rot_dist(4.6, idist) * .6).r;

//	float stars = (1. - smoothstep(0.22, 0.34, mix(sampling3, sampling4, lerp))) * 0.4;

	vec3 kali_dir=vec3(SCREEN_UV * zoom *0.2, 0.1);
	vec3 from=vec3(1.0,0.5,0.5);
	from+=vec3(TIME * 0.001,TIME * 0.001, -2.0);
	vec3 kali_star = kali_stars(from, kali_dir);

	  vec3 sp = mix(sampling1, sampling2, lerp) * vec3(1.);
    sp *= 0.2;
   	sp += kali_star * vec3(0.13, 0.31, 0.46);
    sp += smoothstep(0.26, 0.14, mix(sampling5, sampling6, lerp)) * vec3(0.7) * pow(idist, 8.) * ringOuterColor;

 	vec3 finalSamp = sp;
    vec3 col = ringColor * pow(1.0 - dist, 7.);
    float ring = pow(smoothstep(.32, .08, dist * 1.5) * 3.5, 2.8) + 1.0;

	COLOR = vec4(finalSamp * mask + 1.2 * ring * mask * finalSamp * col, 1.0);
}