$input vWorldPos, vNormal, vTexCoord0, vTexCoord1, vTangent, vBinormal

#include <forward_pipeline.sh>

// Surface attributes
uniform vec4 uBaseOpacityColor;
uniform vec4 uCutoff; // uCutoff.x = alpha cut threshold (default = 0.4)
uniform vec4 uZoetrope;

// Texture slots
SAMPLER2D(uBaseOpacityMap, 0);

float remap(float value, float low1, float high1, float low2, float high2) {
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

// Entry point of the forward pipeline default uber shader (Phong and PBR)
void main() {
	float frame_time = mod(uClock.x, 1.0) * uZoetrope.x; // uZoetrope.x;
	float uv_offset = remap(floor(frame_time), 0.0, (uZoetrope.y - 1.0), 0.0, 1.0 - (1.0 / uZoetrope.y));
	vec2 uv_frame = vTexCoord0 * vec2(1.0, 1.0 / uZoetrope.y) + vec2(0.0, uv_offset);
#if USE_BASE_COLOR_OPACITY_MAP
	vec4 base_opacity = texture2D(uBaseOpacityMap, uv_frame);
	base_opacity.xyz = sRGB2linear(base_opacity.xyz);
#else // USE_BASE_COLOR_OPACITY_MAP
	vec4 base_opacity = uBaseOpacityColor;
#endif // USE_BASE_COLOR_OPACITY_MAP

	vec3 color = base_opacity.xyz;
	// vec3 view = mul(u_view, vec4(vWorldPos, 1.0)).xyz;
	float opacity = base_opacity.w;

#if ENABLE_ALPHA_CUT
	if (opacity < uCutoff.x)
		discard;
#endif // ENABLE_ALPHA_CUT

	float gamma = 2.2;
	color = pow(color, vec3_splat(1. / gamma));

	gl_FragColor = vec4(color, opacity);
}