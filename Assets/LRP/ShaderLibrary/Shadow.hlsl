#ifndef L_SHADOW_INCLUDE
#define L_SHADOW_INCLUDE

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_CASCADE_COUNT 4

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
SAMPLER_CMP(sampler_DirectionalShadowAtlas);

CBUFFER_START(_LShadows)
int _CascadeCount;
float4 _ShadowDistance;
float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
float4 _CascadeData[MAX_CASCADE_COUNT];
float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
CBUFFER_END

//per light
struct DirectionalShadowData
{
    float strength;
    int tileIndex;
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

float GetDirectionalShadowAttenuation(DirectionalShadowData data, ShadowData shadowData, float3 positionWS, float3 normal)
{
    if(data.strength <= 0.0) return 1.0;
    float3 normalBias = normal * _CascadeData[shadowData.cascadeIndex].y;
    float3 shadowCoord = mul(_DirectionalShadowMatrices[data.tileIndex], float4(positionWS + normalBias, 1.0)).xyz;
    float shadow = SampleDirectionalShadowAtlas(shadowCoord);
    return lerp(1.0, shadow, data.strength);
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
#endif