$input vWorldPos, vNormal, vTexCoord0, vTexCoord1, vTangent, vBinormal

#include <forward_pipeline.sh>

// Surface attributes
uniform vec4 uBaseOpacityColor;
uniform vec4 uSelfColor;
uniform vec4 uCutoff; // uCutoff.x = alpha cut threshold (default = 0.4), y = sRGB2linear
uniform vec4 uFlipTexture; // uCutoff.x = frequency

#define M_PI 3.1415926535897932384626433832795

// Texture slots
SAMPLER2D(uBaseOpacityMap, 0);
SAMPLER2D(uSelfMap, 4);

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
	base_opacity.xyz = mix(base_opacity.xyz, sRGB2linear(base_opacity.xyz), uCutoff.y);
#else // USE_BASE_COLOR_OPACITY_MAP
	vec4 base_opacity = uBaseOpacityColor;
#endif // USE_BASE_COLOR_OPACITY_MAP

#if USE_SELF_MAP
	vec4 self = texture2D(uSelfMap, vTexCoord0);
	self.xyz = mix(self.xyz, sRGB2linear(self.xyz), uCutoff.y);
#else // USE_SELF_MAP
	vec4 self = uSelfColor;
#endif // USE_SELF_MAP

	float flip_factor = (sin(mod(uClock.x * uFlipTexture.x, 1.0) * 2.0 * M_PI) + 1.0) * 0.5;
	flip_factor = step(0.5, flip_factor);
	vec3 color = mix(base_opacity.xyz, self.xyz, flip_factor);
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