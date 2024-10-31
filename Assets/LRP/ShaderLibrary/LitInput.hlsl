#ifndef L_LIT_INPUT_INCLUDE
#define L_LIT_INPUT_INCLUDE

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    float4 _BaseColor;
    float4 _EmissionColor;
    float _Metallic;
    float _PerceptualRoughness;
CBUFFER_END

float4 GetBase(float2 uv)
{
    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor;
}
float GetMetallic()
{
    return _Metallic;
}
float GetPerceptualRoughness()
{
    return _PerceptualRoughness;
}

float3 GetEmission(float2 uv)
{
    return _EmissionColor;
}

#endif