#ifndef L_SHADOW_INCLUDE
#define L_SHADOW_INCLUDE

#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"

#if defined(_DIRECTIONAL_PCF3)
    #define DIRECTIONAL_FILTER_SAMPLES 4
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_3x3
#elif defined(_DIRECTIONAL_PCF5)
    #define DIRECTIONAL_FILTER_SAMPLES 9
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_5x5
#elif defined(_DIRECTIONAL_PCF7)
    #define DIRECTIONAL_FILTER_SAMPLES 16
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_7x7
#endif

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_CASCADE_COUNT 4

#define BEYOND_SHADOW_FAR(shadowCoord) shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
SAMPLER_CMP(sampler_DirectionalShadowAtlas);

CBUFFER_START(_LShadows)
int _CascadeCount;
float4 _ShadowDistance;
float4 _ShadowAtlasSize;
float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
float4 _CascadeData[MAX_CASCADE_COUNT];
float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
CBUFFER_END

//per light
struct DirectionalShadowData
{
    float strength;
    int tileIndex;
    float nomralBias;
};

//per frag
struct ShadowData
{
    int cascadeIndex;
    float strength;
};

float SampleDirectionalShadowAtlas(float3 shadowCoord)
{
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, sampler_DirectionalShadowAtlas, shadowCoord);
}
float FadedShadowStrength (float distance, float scale, float fade) {
    return saturate((1.0 - distance * scale) * fade);
}


ShadowData GetShadowData(float3 positionWS, float depth)
{
    ShadowData data;
    data.strength = FadedShadowStrength(depth, _ShadowDistance.x, _ShadowDistance.y);
    int i;
    for (i = 0; i < _CascadeCount; i++)
    {
        float4 sphere = _CascadeCullingSpheres[i];
        float distanceSqr = DistanceSquared(positionWS, sphere.xyz);
        if (distanceSqr < sphere.w)
        {
            if (i == _CascadeCount - 1) {
                data.strength *= FadedShadowStrength(distanceSqr, _CascadeData[i].x, _ShadowDistance.z);
            }
            break;
        }
    }
    data.cascadeIndex = i;
    return data;
}

float FilterDirectionalShadow (float3 positionSTS) {
    #if defined(DIRECTIONAL_FILTER_SETUP)
    float weights[DIRECTIONAL_FILTER_SAMPLES];
    float2 positions[DIRECTIONAL_FILTER_SAMPLES];
    float4 size = _ShadowAtlasSize.yyxx;
    DIRECTIONAL_FILTER_SETUP(size, positionSTS.xy, weights, positions);
    float shadow = 0;
    for (int i = 0; i < DIRECTIONAL_FILTER_SAMPLES; i++) {
        shadow += weights[i] * SampleDirectionalShadowAtlas(
            float3(positions[i].xy, positionSTS.z)
        );
    }
    return shadow;
    #else
    return SampleDirectionalShadowAtlas(positionSTS);
    #endif
}

float GetDirectionalShadowAttenuation(DirectionalShadowData data, ShadowData shadowData, Surface surface)
{
    if(data.strength <= 0.0) return 1.0;
    float3 normalBias = surface.normal * data.nomralBias * _CascadeData[shadowData.cascadeIndex].y;
    float3 shadowCoord = mul(_DirectionalShadowMatrices[data.tileIndex], float4(surface.position + normalBias, 1.0)).xyz;
    float shadow = FilterDirectionalShadow(shadowCoord);
    float val = lerp(1.0, shadow, data.strength);
    return BEYOND_SHADOW_FAR(shadowCoord) ? 1.0 : val;
}
#endif