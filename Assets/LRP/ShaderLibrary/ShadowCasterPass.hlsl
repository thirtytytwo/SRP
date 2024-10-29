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

    #if UNITY_REVERSED_Z
    output.positionCS.z = min(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
    #else
    output.positionCS.z = max(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
    #endif
    return output ;
}

half4 ShadowCasterFragment(Varying input) : SV_TARGET
{
    return 0;
}
#endif