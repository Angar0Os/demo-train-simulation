$input vWorldPos, vNormal, vTexCoord0, vTexCoord1, vTangent, vBinormal

#include <forward_pipeline.sh>

// Surface attributes
uniform vec4 uBaseOpacityColor;
// Texture slots
SAMPLER2D(uBaseOpacityMap, 0);

// Entry point of the forward pipeline default uber shader (Phong and PBR)
void main() {
#if USE_BASE_COLOR_OPACITY_MAP
	vec4 base_opacity = texture2D(uBaseOpacityMap, vTexCoord0);
	base_opacity.xyz = sRGB2linear(base_opacity.xyz);
#else // USE_BASE_COLOR_OPACITY_MAP
	vec4 base_opacity = uBaseOpacityColor;
#endif // USE_BASE_COLOR_OPACITY_MAP

	float gamma = 2.2;
	base_opacity.xyz = pow(base_opacity.xyz, vec3_splat(1. / gamma));

	gl_FragColor = base_opacity;
}