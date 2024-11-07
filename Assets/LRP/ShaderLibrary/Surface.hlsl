#ifndef L_SURFACE_INCLUDE
#define L_SURFACE_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#define MIN_REFLECTIVITY 0.04
struct Surface
{
    float3 position;
    float3 normal;
    float3 viewDirection;
    float3 color;
    float  alpha;
    float  metallic;
    float  percetualRoughness;
};

struct BRDF
{
    float3 diffuse;
    float3 specular;
    float roughness;
};

Surface GetSurface( float3 position, float3 normal, float3 viewDir, float4 color, float roughness, float metallic)
{
    Surface surface;
    surface.normal = normal;
    surface.color = color.rgb;
    surface.alpha = color.a;
    surface.metallic = metallic;
    surface.percetualRoughness = roughness;
    surface.viewDirection = viewDir;
    surface.position = position;
    return surface;
}
BRDF GetBRDF(Surface surface, bool premulAlpha = false)
{
    BRDF brdf;
    //metallic
    float range = 1.0 - MIN_REFLECTIVITY;
    brdf.diffuse = surface.color * (range - surface.metallic * range);
    //其实也是一个遵循能量守恒的插值，只不过在只有漫反射的时候(非金属),specular不会影响物体表面的颜色
    brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);
    brdf.roughness = PerceptualRoughnessToRoughness(surface.percetualRoughness);
    return brdf;
}

float3 IndirectBRDF(Surface surface, BRDF brdf, float3 diffuse, float3 specular)
{
    float3 reflection = specular * brdf.specular;
    reflection /= brdf.roughness * brdf.roughness + 1.0;
    return diffuse * brdf.diffuse + reflection;
}
#endif