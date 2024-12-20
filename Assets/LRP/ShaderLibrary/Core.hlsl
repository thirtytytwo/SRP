#ifndef L_CORE_INCLUDE
#define L_CORE_INCLUDE
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "UnityInput.hlsl"
#ifdef _SHADOW_MASK_DISTANCE
    #define SHADOW_SHADOWMASK
#endif
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

float DistanceSquared(float3 a, float3 b)
{
    return dot(a - b, a - b);
}
#endif
