$input vWorldPos, vNormal, vTexCoord0, vTexCoord1, vTangent, vBinormal

#include <forward_pipeline.sh>

// Surface attributes
uniform vec4 uBaseOpacityColor;
uniform vec4 uCutoff; // uCutoff.x = alpha cut threshold (default = 0.4)

// Texture slots
SAMPLER2D(uBaseOpacityMap, 0);

//
vec3 DistanceFog(vec3 pos, vec3 color) {
	if (uFogState.y == 0.0)
		return color;

	float k = clamp((pos.z - uFogState.x) * uFogState.y, 0.0, 1.0);
	return mix(color, uFogColor.xyz, k);
}

// Entry point of the forward pipeline default uber shader (Phong and PBR)
void main() {
#if USE_BASE_COLOR_OPACITY_MAP
	vec4 base_opacity = texture2D(uBaseOpacityMap, vTexCoord0);
	base_opacity.xyz = sRGB2linear(base_opacity.xyz);
#else // USE_BASE_COLOR_OPACITY_MAP
	vec4 base_opacity = uBaseOpacityColor;
#endif // USE_BASE_COLOR_OPACITY_MAP

	vec3 color = base_opacity.xyz * uAmbientColor.xyz;
	vec3 view = mul(u_view, vec4(vWorldPos, 1.0)).xyz;
	color = DistanceFog(view, color);
	float opacity = base_opacity.w;

#if ENABLE_ALPHA_CUT
	if (opacity < uCutoff.x)
		discard;
#endif // ENABLE_ALPHA_CUT

	float gamma = 2.2;
	color = pow(color, vec3_splat(1. / gamma));

	gl_FragColor = vec4(color, opacity);
}