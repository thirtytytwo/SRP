#ifndef L_LIT_PASS_INCLUDE
#define L_LIT_PASS_INCLUDE


#include "Assets/LRP/ShaderLibrary/Surface.hlsl"
#include "Assets/LRP/ShaderLibrary/Shadow.hlsl"
#include "Assets/LRP/ShaderLibrary/Lighting.hlsl"

#define MIN_ROUGHNESS 0.3
#if defined(LIGHTMAP_ON)
    #define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1;
    #define GI_VARYING_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
    #define TRANSFER_GI_DATA(input, output) output.lightMapUV = input.lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
    #define GI_FRAGMENT_DATA(input) input.lightMapUV
#else
    #define GI_ATTRIBUTE_DATA
    #define GI_VARYING_DATA
    #define TRANSFER_GI_DATA(input, output)
    #define GI_FRAGMENT_DATA(input) 0.0
#endif
struct Attribute
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
    GI_ATTRIBUTE_DATA
};

struct Varying
{
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD2;
    float3 normalWS : TEXCOORD1;
    float2 uv : TEXCOORD0;
    GI_VARYING_DATA
};


Varying LitVertex(Attribute input)
{
    Varying output;
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    TRANSFER_GI_DATA(input, output);
    return output;
}

half4 LitFragment(Varying input) : SV_Target
{
#ifdef LOD_FADE_CROSSFADE
    float dither = InterleavedGradientNoise(input.positionCS.xy, 0);
    clip(unity_LODFade.x + (unity_LODFade.x < 0.0 ? dither : -dither));
#endif
    float3 viewDir = normalize(_WorldSpaceCameraPos - input.positionWS);
    float3 normal = normalize(input.normalWS);
    float3 position = input.positionWS;
    float4 baseCol = GetBase(input.uv);
    float depthView = -TransformWorldToView(position).z;
    float perceptualRoughness = clamp(GetPerceptualRoughness(), MIN_ROUGHNESS, 1.0f);
    Surface surface = GetSurface(position, normal, viewDir, baseCol, perceptualRoughness, GetMetallic());
    BRDF brdf = GetBRDF(surface);
    GI gi = GetGI(GI_FRAGMENT_DATA(input), surface);
    half3 color = IndirectBRDF(surface, brdf, gi.diffuseIndir, gi.specularIndir);
    ShadowData data = GetShadowData(position, depthView);
    data.shadowMask = gi.shadowMask;
    //return data.shadowMask.shadows;
    for(int i = 0; i < GetDirectionalLightCount(); i++)
    {
        Light light = GetDirLights(i);
        DirectionalShadowData shadowData = GetDirectionalShadowData(i, data);
        shadowData.strength *= data.strength;
        light.attenuation = GetDirectionalShadowAttenuation(shadowData, data, surface);
        color += PBRBaseRendering(brdf, surface, light);
    }
    for(int j = 0; j < GetOtherLightCount(); j++)
    {
        Light light = GetOtherLights(j, surface, data);
        color += PBRBaseRendering(brdf, surface, light);
    }
    //临时加间接漫反射
    color += gi.diffuseIndir;
    return half4(color, surface.alpha);
}
#endif