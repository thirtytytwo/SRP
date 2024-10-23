#ifndef L_LIGHTING_INCLUDE
#define L_LIGHTING_INCLUDE
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

#define MAX_LIGHT_COUNT 4

CBUFFER_START(_Light)
    int _DirectionalLightCount;
    float3 _DirectionalLightColor[MAX_LIGHT_COUNT];
    float3 _DirectionalLightDirection[MAX_LIGHT_COUNT];
CBUFFER_END

struct Light
{
    float3 color;
    float3 direction;
};

int GetDirectionalLightCount()
{
    return _DirectionalLightCount;
}
Light GetMainLight(int index)
{
    Light light;
    light.color = _DirectionalLightColor[index];
    light.direction = _DirectionalLightDirection[index];
    return light;
}
#endif