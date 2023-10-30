shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D curveSample;
uniform float strength: hint_range(-1.0, 1.0) = 0.5;
uniform float rotationSpeed: hint_range(-1.0, 10.0, 0.1) = 1.0;

void fragment() {
	vec2 center = vec2(0.5,0.5) - UV;
	float distanceToCenter = length(center);

	float rotationAngle = rotationSpeed * distanceToCenter + TIME;

	mat2 rotation = mat2(vec2(cos(rotationAngle), -sin(rotationAngle)), vec2(sin(rotationAngle), cos(rotationAngle)));
	vec2 rotatedUV = UV + rotation * center;
	float curveValue = texture(curveSample, vec2(distanceToCenter)).r;
	vec2 difference = normalize(center) * strength * curveValue;
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV - rotatedUV + difference);

//	vec2 center = vec2(0.5,0.5) - UV;
//	float distanceToCenter = length(center);
//	float curveValue = texture(curveSample, vec2(distanceToCenter)).r;
//	vec2 difference = normalize(center) * strength * curveValue;
//	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV - difference);
	}
