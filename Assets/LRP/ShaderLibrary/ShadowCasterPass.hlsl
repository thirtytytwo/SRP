#ifndef L_SHADOW_CASTER_PASS_INCLUDE
#define L_SHADOW_CASTER_PASS_INCLUDE
#include "Assets/LRP/ShaderLibrary/Core.hlsl"

struct Attribute
{
    float3 positionOS : POSITION;
};

struct Varying
{
    float4 positionCS : SV_POSITION;
};

Varying ShadowCasterVertex(Attribute input)
{
    Varying output;
    float3 positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(positionWS);
    return output;
}

half4 ShadowCasterFragment(Varying input) : SV_TARGET
{
    return 0;
}
#endif