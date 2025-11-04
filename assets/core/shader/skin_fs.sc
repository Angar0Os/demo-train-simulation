$input vWorldPos, vNormal, vTangent, vBinormal, vTexCoord0, vTexCoord1, vLinearShadowCoord0, vLinearShadowCoord1, vLinearShadowCoord2, vLinearShadowCoord3, vSpotShadowCoord, vProjPos, vPrevProjPos

// HARFANG(R) Copyright (C) 2022 Emmanuel Julien, NWNC HARFANG. Released under GPL/LGPL/Commercial Licence, see licence.txt for details.
#include <forward_pipeline.sh>

// Surface attributes
uniform vec4 uParam; // uParam.x = normal intensity (default = 1.0), uParam.y = specular dimming (default = 0.0)
uniform vec4 uSkinChroma0; // RGB color for the skin tone #1
uniform vec4 uSkinChroma1; // RGB color for the skin tone #2

// Texture slots
SAMPLER2D(uBaseOpacityMap, 0);
SAMPLER2D(uOcclusionRoughnessMetalnessMap, 1);
SAMPLER2D(uNormalMap, 2);
// SAMPLER2D(uAmbientMap, 6);

#define SSS_SAMPLES 36.0f

float chromaKey(vec3 fragmentColor, vec3 keyColor, float tolerance) {
    float distance = length(fragmentColor - keyColor);
    float alpha = 1.0 - smoothstep(0.0, tolerance, distance);

    return alpha;
}

float Gaussian ( float v, float r )
{
	return 1.0f/sqrt(2.0f*PI*v)*exp(-(r*r)/(2.0f*v));
}

vec3 Scatter ( float r )
{
    return Gaussian ( 0.0064f * 1.414f , r ) * vec3( 0.233f , 0.455f , 0.649f ) +
    	   Gaussian ( 0.0484f * 1.414f , r ) * vec3( 0.100f , 0.336f , 0.344f ) +
    	   Gaussian ( 0.1870f * 1.414f , r ) * vec3( 0.118f , 0.198f , 0.000f ) +
    	   Gaussian ( 0.5670f * 1.414f , r ) * vec3( 0.113f , 0.007f , 0.007f ) +
    	   Gaussian ( 1.9900f * 1.414f , r ) * vec3( 0.358f , 0.004f , 0.000f ) +
    	   Gaussian ( 7.4100f * 1.414f , r ) * vec3( 0.078f , 0.000f , 0.000f ) ;
}

vec3 CalculateSS(float r, vec3 lightDir, vec3 normal) {
    float angle = acos(dot(normal, lightDir * -1.0f));

    vec2 L = vec2(1.0f,0.0f);
	float stepOffset = 2.0f*PI/SSS_SAMPLES * r;

    float angleOffset = 0.0f;

    vec3 totalLight = vec3_splat(0.0f);
    vec3 totalWeights = vec3_splat(0.0f);

    for( float i = 0.0f; i < SSS_SAMPLES; i++){

        float segment = 2.0f * r * sin(angleOffset * 0.5f);

        float surfacePointAngle =  angle + angleOffset + 2.0f * PI;
        float NdotL = max(0.0f,cos(surfacePointAngle));

        vec3 weights = Scatter(segment);
        totalWeights += weights;
        totalLight += NdotL * weights;

        angleOffset += stepOffset;
    }

    return 2.0 * pow(totalLight / totalWeights, 2.0);
}

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

//
float LightAttenuation(vec3 L, vec3 D, float dist, float attn, float inner_rim, float outer_rim) {
	float k = 1.0;
	if (attn > 0.0)
		k = max(1.0 - dist * attn, 0.0); // distance attenuation

	if (outer_rim > 0.0) {
		float c = dot(L, D);
		k *= clamp(1.0 - (c - inner_rim) / (outer_rim - inner_rim), 0.0, 1.0); // spot attenuation
	}
	return k;
}

float SampleHardShadow(sampler2DShadow map, vec4 coord, float bias) {
	vec3 uv = coord.xyz / coord.w;
	return shadow2D(map, vec3(uv.xy, uv.z - bias));
}

float SampleShadowPCF(sampler2DShadow map, vec4 coord, float inv_pixel_size, float bias, vec4 jitter) {
	float k_pixel_size = inv_pixel_size * coord.w;

	float k = 0.0;

#if FORWARD_PIPELINE_AAA
	#define PCF_SAMPLE_COUNT 2 // 3x3

	ARRAY_BEGIN(float, weights, 9) 0.011147, 0.083286, 0.011147, 0.083286, 0.622269, 0.083286, 0.011147, 0.083286, 0.011147 ARRAY_END();

	for (int j = 0; j <= PCF_SAMPLE_COUNT; ++j) {
		float v = 6.0 * (float(j) + jitter.y) / float(PCF_SAMPLE_COUNT) - 1.0;
		for (int i = 0; i <= PCF_SAMPLE_COUNT; ++i) {
			float u = 6.0 * (float(i) + jitter.x) / float(PCF_SAMPLE_COUNT) - 1.0;
			k += SampleHardShadow(map, coord + vec4(vec2(u, v) * k_pixel_size, 0.0, 0.0), bias) * weights[j * 3 + i];
		}
	}
#else // FORWARD_PIPELINE_AAA
	// 2x2
	k += SampleHardShadow(map, coord + vec4(vec2(-0.5, -0.5) * k_pixel_size, 0.0, 0.0), bias);
	k += SampleHardShadow(map, coord + vec4(vec2( 0.5, -0.5) * k_pixel_size, 0.0, 0.0), bias);
	k += SampleHardShadow(map, coord + vec4(vec2(-0.5,  0.5) * k_pixel_size, 0.0, 0.0), bias);
	k += SampleHardShadow(map, coord + vec4(vec2( 0.5,  0.5) * k_pixel_size, 0.0, 0.0), bias);

	k /= 4.0;
#endif // FORWARD_PIPELINE_AAA

	return k;
}

// Forward PBR GGX
float DistributionGGX(float NdotH, float roughness) {
	float a = roughness * roughness;
	float a2 = a * a;

	float divisor = NdotH * NdotH * (a2 - 1.0) + 1.0;
	return a2 / max(PI * divisor * divisor, 1e-8);
}

float GeometrySchlickGGX(float NdotW, float k) {
	float div = NdotW * (1.0 - k) + k;
	return NdotW / ((abs(div) > 1e-8) ? div : 1e-8);
}

float GeometrySmith(float NdotV, float NdotL, float roughness) {
	float r = roughness + 1.0;
	float k = (r * r) / 8.0;
	float ggx2 = GeometrySchlickGGX(NdotV, k);
	float ggx1 = GeometrySchlickGGX(NdotL, k);
	return ggx1 * ggx2;
}

vec3 FresnelSchlick(float cosTheta, vec3 F0) {
	return F0 + (1.0 - F0) * pow(max(1.0 - cosTheta, 0.0), 5.0);
}

vec3 FresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness) {
	return F0 + (max(vec3_splat(1.0 - roughness), F0) - F0) * pow(max(1.0 - cosTheta, 0.0), 5.0);
}

vec3 GGX(vec3 V, vec3 N, float NdotV, vec3 L, vec3 albedo, float roughness, float metalness, vec3 F0, vec3 diffuse_color, vec3 specular_color) {
	vec3 H = normalize(V - L);

	float NdotH = max(dot(N, H), 0.0);
	float NdotL = max(-dot(N, L), 0.0);
	float HdotV = max(dot(H, V), 0.0);

	float D = DistributionGGX(NdotH, roughness);
	float G = GeometrySmith(NdotV, NdotL, roughness);
	vec3 F = FresnelSchlick(HdotV, F0);

	vec3 specularBRDF = (F * D * G) / max(4.0 * NdotV * NdotL, 0.001);

	vec3 kD = (vec3_splat(1.0) - F) * (1.0 - metalness); // metallic materials have no diffuse (NOTE: mimics mental ray and 3DX Max ART renderers behavior)
	vec3 diffuseBRDF = kD * albedo;

	return (diffuse_color * diffuseBRDF + specular_color * specularBRDF) * NdotL;
}

//
vec3 DistanceFog(vec3 pos, vec3 color) {
	if (uFogState.y == 0.0)
		return color;

	float k = clamp((pos.z - uFogState.x) * uFogState.y, 0.0, 1.0);
	return mix(color, uFogColor.xyz, k);
}

// Entry point of the forward pipeline default uber shader (Phong and PBR)
void main() {
	//
	vec4 base_opacity = texture2D(uBaseOpacityMap, vTexCoord0);
	base_opacity.xyz = sRGB2linear(base_opacity.xyz);

	float skin_chroma = max(chromaKey(base_opacity.xyz, uSkinChroma0, 1.0), chromaKey(base_opacity.xyz, uSkinChroma1, 1.0));
	vec4 base_sss; // = texture2D(uAmbientMap, vTexCoord0);
	base_sss.x = skin_chroma;
	base_sss.y = 0.0;
	base_sss.z = 0.0;

#if DEPTH_ONLY != 1
	vec4 occ_rough_metal = texture2D(uOcclusionRoughnessMetalnessMap, vTexCoord0);
	//
	vec3 view = mul(u_view, vec4(vWorldPos, 1.0)).xyz;
	vec3 P = vWorldPos; // fragment world pos
	vec3 V = normalize(GetT(u_invView) - P); // world space view vector
	vec3 N = sign(dot(V, vNormal)) * normalize(vNormal); // geometry normal

	vec3 T = normalize(vTangent);
	vec3 B = normalize(vBinormal);

	mat3 TBN = mtxFromRows(T, B, N);

	vec3 Nt; // textured normal
	Nt.xy = texture2D(uNormalMap, vTexCoord0).xy * 2.0 - 1.0;
	Nt.z = sqrt(1.0 - dot(Nt.xy, Nt.xy));
	Nt = normalize(mul(Nt, TBN));
	N = mix(N, Nt, uParam.x);

	vec3 R = reflect(-V, N); // view reflection vector around normal

	float NdotV = clamp(dot(N, V), 0.0, 0.99);

	vec3 F0 = vec3(0.04, 0.04, 0.04);
	F0 = mix(F0, base_opacity.xyz, occ_rough_metal.b);

	vec3 color = vec3(0.0, 0.0, 0.0);

	// jitter
#if FORWARD_PIPELINE_AAA
	vec4 jitter = texture2D(uNoiseMap, mod(gl_FragCoord.xy, vec2(64, 64)) / vec2(64, 64));
#else // FORWARD_PIPELINE_AAA
	vec4 jitter = vec4_splat(0.);
#endif // FORWARD_PIPELINE_AAA

	// SLOT 0: linear light
	{
		float k_shadow = 1.0;
#if SLOT0_SHADOWS
		float k_fade_split = 1.0 - jitter.z * 0.3;

		if(view.z < uLinearShadowSlice.x * k_fade_split) {
			k_shadow *= SampleShadowPCF(uLinearShadowMap, vLinearShadowCoord0, uShadowState.y * 0.5, uShadowState.z, jitter);
		} else if(view.z < uLinearShadowSlice.y * k_fade_split) {
			k_shadow *= SampleShadowPCF(uLinearShadowMap, vLinearShadowCoord1, uShadowState.y * 0.5, uShadowState.z, jitter);
		} else if(view.z < uLinearShadowSlice.z * k_fade_split) {
			k_shadow *= SampleShadowPCF(uLinearShadowMap, vLinearShadowCoord2, uShadowState.y * 0.5, uShadowState.z, jitter);
		} else if(view.z < uLinearShadowSlice.w * k_fade_split) {
#if FORWARD_PIPELINE_AAA
			k_shadow *= SampleShadowPCF(uLinearShadowMap, vLinearShadowCoord3, uShadowState.y * 0.5, uShadowState.z, jitter);
#else // FORWARD_PIPELINE_AAA
			float pcf = SampleShadowPCF(uLinearShadowMap, vLinearShadowCoord3, uShadowState.y * 0.5, uShadowState.z, jitter);
			float ramp_len = (uLinearShadowSlice.w - uLinearShadowSlice.z) * 0.25;
			float ramp_k = clamp((view.z - (uLinearShadowSlice.w - ramp_len)) / max(ramp_len, 1e-8), 0.0, 1.0);
			k_shadow *= pcf * (1.0 - ramp_k) + ramp_k;
#endif // FORWARD_PIPELINE_AAA
		}
#endif // SLOT0_SHADOWS
		vec3 color_base = color + GGX(V, N, NdotV, uLightDir[0].xyz, base_opacity.xyz, occ_rough_metal.g, occ_rough_metal.b, F0, uLightDiffuse[0].xyz * k_shadow, uLightSpecular[0].xyz * k_shadow);
		vec3 color_SSS = color + CalculateSS(uParam.z, uLightDir[0].xyz, N) * uParam.w * GGX(V, N, NdotV, uLightDir[0].xyz, base_opacity.xyz, occ_rough_metal.g, occ_rough_metal.b, F0, uLightDiffuse[0].xyz * k_shadow, uLightSpecular[0].xyz * k_shadow);
		color = min(color_base, color_SSS);
		// color += ;
	}
	// SLOT 1: point/spot light (with optional shadows)
	{
		vec3 L = P - uLightPos[1].xyz;
		float distance = length(L);
		L /= max(distance, 1e-8);
		float attenuation = LightAttenuation(L, uLightDir[1].xyz, distance, uLightPos[1].w, uLightDir[1].w, uLightDiffuse[1].w);

#if SLOT1_SHADOWS
		attenuation *=SampleShadowPCF(uSpotShadowMap, vSpotShadowCoord, uShadowState.y, uShadowState.w, jitter);
#endif // SLOT1_SHADOWS
		color += GGX(V, N, NdotV, L, base_opacity.xyz, occ_rough_metal.g, occ_rough_metal.b, F0, uLightDiffuse[1].xyz * attenuation, uLightSpecular[1].xyz * attenuation);
	}
	// SLOT 2-N: point/spot light (no shadows) [todo]
	{
		for (int i = 2; i < 8; ++i) {
			vec3 L = P - uLightPos[i].xyz;
			float distance = length(L);
			L /= max(distance, 1e-8);
			float attenuation = LightAttenuation(L, uLightDir[i].xyz, distance, uLightPos[i].w, uLightDir[i].w, uLightDiffuse[i].w);

			color += GGX(V, N, NdotV, L, base_opacity.xyz, occ_rough_metal.g, occ_rough_metal.b, F0, uLightDiffuse[i].xyz * attenuation, uLightSpecular[i].xyz * attenuation);
		}
	}

	// IBL
	float MAX_REFLECTION_LOD = 10.;
#if 0 // LOD selection
	vec3 Ndx = normalize(N + ddx(N));
	float dx = length(Ndx.xy / Ndx.z - N.xy / N.z) * 256.0;
	vec3 Ndy = normalize(N + ddy(N));
	float dy = length(Ndy.xy / Ndy.z - N.xy / N.z) * 256.0;

	float dd = max(dx, dy);
	float lod_level = log2(dd);
#endif

	vec3 irradiance = textureCube(uIrradianceMap, ReprojectProbe(P, N)).xyz;
	vec3 radiance = textureCubeLod(uRadianceMap, ReprojectProbe(P, R), occ_rough_metal.y * MAX_REFLECTION_LOD).xyz;

#if FORWARD_PIPELINE_AAA
	vec4 ss_irradiance = texture2D(uSSIrradianceMap, gl_FragCoord.xy / uResolution.xy);
	vec4 ss_radiance = texture2D(uSSRadianceMap, gl_FragCoord.xy / uResolution.xy);

	irradiance = ss_irradiance.xyz; // mix(irradiance, ss_irradiance, ss_irradiance.w);
	radiance = mix(radiance, ss_radiance.xyz, ss_radiance.w);
#endif

	vec3 diffuse = irradiance * base_opacity.xyz;
	vec3 F = FresnelSchlickRoughness(NdotV, F0, occ_rough_metal.y);
	vec2 brdf = texture2D(uBrdfMap, vec2(NdotV, occ_rough_metal.y)).xy;
	vec3 sheen_color = mix(vec3(1.0, 1.0, 1.0), vec3(1.0, 0.25, 0.15), base_sss.x);
	float sheen_strength = mix(uParam.y, 1.0, base_sss.x);
	vec3 specular = (radiance * (F * brdf.x + brdf.y)) * mix(1.0, 1.0 -  occ_rough_metal.y * occ_rough_metal.y, sheen_strength) * sheen_color;
#if FORWARD_PIPELINE_AAA
	specular *= uAAAParams[2].x; // * specular weight
#endif

	vec3 kS = specular;
	vec3 kD = vec3_splat(1.) - kS;
	kD *= 1. - occ_rough_metal.z;

	color += kD * diffuse;
	color += specular;
	// color += uAmbientColor.xyz;
	color *= occ_rough_metal.x;

	color = DistanceFog(view, color);
#endif // DEPTH_ONLY != 1

	float opacity = base_opacity.w;

#if ENABLE_ALPHA_CUT
	if (opacity < 0.4)
		discard;
#endif // ENABLE_ALPHA_CUT

#if DEPTH_ONLY != 1
#if FORWARD_PIPELINE_AAA_PREPASS
	vec3 N_view = mul(u_view, vec4(N, 0)).xyz;
	vec2 velocity = vec2(vProjPos.xy / vProjPos.w - vPrevProjPos.xy / vPrevProjPos.w);
	gl_FragData[0] = vec4(N_view.xyz, vProjPos.z);
	gl_FragData[1] = vec4(velocity.xy, occ_rough_metal.y, 0.);
#else // FORWARD_PIPELINE_AAA_PREPASS
	// incorrectly apply gamma correction at fragment shader level in the non-AAA pipeline
#if FORWARD_PIPELINE_AAA != 1
	float gamma = 2.2;
	color = pow(color, vec3_splat(1. / gamma));
#endif // FORWARD_PIPELINE_AAA != 1
	// color = base_sss.xyz;
	gl_FragColor = vec4(color, opacity);
#endif // FORWARD_PIPELINE_AAA_PREPASS
#else
	gl_FragColor = vec4_splat(0.0); // note: fix required to stop glsl-optimizer from removing the whole function body
#endif // DEPTH_ONLY
}
