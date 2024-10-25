#ifndef L_SURFACE_INCLUDE
#define L_SURFACE_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#define MIN_REFLECTIVITY 0.04
struct Surface
{
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

Surface GetSurface( float3 normal, float3 viewDir, float4 color, float roughness, float metallic)
{
    Surface surface;
    surface.normal = normal;
    surface.color = color.rgb;
    surface.alpha = color.a;
    surface.metallic = metallic;
    surface.percetualRoughness = roughness;
    surface.viewDirection = viewDir;
    return surface;
}
BRDF GetBRDF(Surface surface, bool premulAlpha = false)
{
    BRDF brdf;
    //metallic
    float range = 1.0 - MIN_REFLECTIVITY;
    brdf.diffuse = surface.color * (range - surface.metallic * range);
    //��ʵҲ��һ����ѭ�����غ�Ĳ�ֵ��ֻ������ֻ���������ʱ��(�ǽ���),specular����Ӱ������������ɫ
    brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);
    brdf.roughness = PerceptualRoughnessToRoughness(surface.percetualRoughness);
    return brdf;
}
#endif