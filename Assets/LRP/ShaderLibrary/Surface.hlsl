#ifndef L_SURFACE_INCLUDE
#define L_SURFACE_INCLUDE

struct Surface
{
    float3 normal;
    float3 viewDirection;
    float3 color;
    float  alpha;
    float  metallic;
    float  smoothness;
};

struct BRDF
{
    float3 diffuse;
    float3 specular;
    float roughness;
};

Surface GetSurface(float3 normal, float3 color, float alpha)
{
    Surface surface;
    surface.normal = normal;
    surface.color = color;
    surface.alpha = alpha;
    return surface;
}
BRDF GetBRDF(Surface surface)
{
    
}
#endif