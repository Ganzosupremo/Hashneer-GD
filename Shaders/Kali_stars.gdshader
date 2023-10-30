shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform int iterations: hint_range(15, 20) = 17;
uniform float formuparam: hint_range(0.0, 1.0) = 0.69;
uniform int volSteps = 20;
uniform float stepSize = 0.1;
uniform float tile = 0.850;
uniform float speed = 0.010;
uniform float zoom  = 0.800;
uniform float brightness = 0.0015;
uniform float darkmatter = 0.300;
uniform float distfading = 0.730;
uniform float saturation = 0.850;


void fragment() {
	vec2 uv = FRAGCOORD.xy/SCREEN_PIXEL_SIZE.xy - .5;
	uv.y * SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x;
	vec3 dir=vec3(SCREEN_UV * zoom, 1.0);
	float time = TIME * speed;
	
	//mouse rotation
//	float a1=.5+ /SCREEN_PIXEL_SIZE.x*2.;
//	float a2=.8+iMouse.y/iResolution.y*2.;
//	mat2 rot1=mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
//	mat2 rot2=mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
//	dir.xz*=rot1;
//	dir.xy*=rot2;
	vec3 from=vec3(1.0,0.5,0.5);
	from+=vec3(time*2.0,time,-2.0);
//	from.xz*=rot1;
//	from.xy*=rot2;
	
	//volumetric rendering
	float s = 0.1,fade = 1.0;
	vec3 v = vec3(0.0);
	for(int r=0; r<volSteps; r++){
		vec3 p = s*dir*.5;
		p = abs(vec3(tile)-mod(p,vec3(tile*2.))); // tiling fold
		float pa,a=pa=0.;
		for (int i=0; i<iterations; i++){
			p=abs(p)/dot(p,p)-formuparam; // the magic formula
			a+=abs(length(p)-pa); // absolute sum of average change
			pa=length(p);
		}
		float dm = max(0.,darkmatter-a*a*.001); //dark matter
		a*=a*a; // add contrast
		if (r>6) fade*=1.-dm; // dark matter, don't render near
		//v+=vec3(dm,dm*.5,0.);
		v+=fade;
		v+=vec3(s,s*s,s*s*s*s)*a*brightness*fade; // coloring based on distance
		fade*=distfading; // distance fading
		s+=stepSize;
	}
	v=mix(vec3(length(v)),v,saturation); //color adjust
	COLOR = vec4(v*.01,1.0);
}
