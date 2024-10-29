#ifndef L_LIGHTING_INCLUDE
#define L_LIGHTING_INCLUDE
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

#define MAX_LIGHT_COUNT 4

CBUFFER_START(_Light)
    int _DirectionalLightCount;
    float4 _DirectionalLightColor[MAX_LIGHT_COUNT];
    float4 _DirectionalLightDirection[MAX_LIGHT_COUNT];
    float4 _DirectionalLightShadowData[MAX_LIGHT_COUNT];
CBUFFER_END

struct Light
{
    float3 color;
    float3 direction;
    float attenuation;
};

int GetDirectionalLightCount()
{
    return _DirectionalLightCount;
}

DirectionalShadowData GetDirectionalShadowData(int index, ShadowData shadowData)
{
    DirectionalShadowData data;
    data.strength = _DirectionalLightShadowData[index].x;
    data.tileIndex = _DirectionalLightShadowData[index].y + shadowData.cascadeIndex;
    data.nomralBias = _DirectionalLightShadowData[index].z;
    return data;
}
Light GetMainLight(int index)
{
    Light light;
    light.color = _DirectionalLightColor[index];
    light.direction = _DirectionalLightDirection[index];
    light.attenuation = 1.0;
    return light;
}

float GGXNormalDistribution(float3 normal, float3 halfVector, float roughness)
{
    float alpha = roughness * roughness;
    float alphaSq = alpha * alpha;
    float NdotH = max(dot(normal, halfVector), 0.0);
    float NdotHSq = NdotH * NdotH;

    float numerator = alphaSq;
    float denominator = (NdotHSq * (alphaSq - 1.0) + 1.0);
    denominator = PI * denominator * denominator;

    return numerator / denominator;
}

float FresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float GeometrySmith(float3 normal, float3 viewDir, float3 lightDir, float roughness)
{
    float NdotV = max(dot(normal, viewDir), 0.0);
    float NdotL = max(dot(normal, lightDir), 0.0);
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;

    float G1V = NdotV / (NdotV * (1.0 - k) + k);
    float G1L = NdotL / (NdotL * (1.0 - k) + k);

    return G1V * G1L;
}

float3 PBRBaseRendering(BRDF brdf, Surface surface, Light light)
{
    float3 halfVector = normalize(light.direction + surface.viewDirection);
    float NDF = GGXNormalDistribution(surface.normal, halfVector, brdf.roughness);
    float G = GeometrySmith(surface.normal, surface.viewDirection, light.direction, brdf.roughness);
    float3 F0 = lerp(float3(MIN_REFLECTIVITY, MIN_REFLECTIVITY, MIN_REFLECTIVITY), surface.color, surface.metallic);
    float3 F = FresnelSchlick(max(dot(halfVector, surface.viewDirection), 0.0), F0);

    float3 numerator = NDF * G * F;
    float denominator = 4.0 * max(dot(surface.normal, surface.viewDirection), 0.0) * max(dot(surface.normal, light.direction), 0.0) + 0.001; // Prevent division by zero
    float3 specular = numerator / denominator;

    float3 kS = F;
    float3 kD = 1.0 - kS;
    kD *= 1.0 - surface.metallic;

    float NdotL = max(dot(surface.normal, light.direction), 0.0);
    float3 diffuse = brdf.diffuse / PI;

    return (kD * diffuse + specular) * light.color * NdotL * light.attenuation;
}
#endif