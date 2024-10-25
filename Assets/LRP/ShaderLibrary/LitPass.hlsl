#ifndef L_LIT_PASS_INCLUDE
#define L_LIT_PASS_INCLUDE

#include "Assets/LRP/ShaderLibrary/Core.hlsl"
#include "Assets/LRP/ShaderLibrary/Surface.hlsl"
#include "Assets/LRP/ShaderLibrary/Shadow.hlsl"
#include "Assets/LRP/ShaderLibrary/Lighting.hlsl"

#define MIN_ROUGHNESS 0.3

struct Attribute
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Varying
{
    float4 positionSS : SV_POSITION;
    float3 positionWS : TEXCOORD2;
    float3 normalWS : TEXCOORD1;
    float2 uv : TEXCOORD0;
};


Varying LitVertex(Attribute input)
{
    Varying output;
    output.positionSS = TransformObjectToHClip(input.positionOS.xyz);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.uv = input.uv;
    return output;
}

half4 LitFragment(Varying input) : SV_Target
{
    float3 viewDir = normalize(_WorldSpaceCameraPos - input.positionWS);
    float3 normal = normalize(input.normalWS);
    float3 position = input.positionWS;
    float depthView = -TransformWorldToView(position).z;
    float perceptualRoughness = clamp(_PerceptualRoughness, MIN_ROUGHNESS, 1.0f);
    Surface surface = GetSurface(normal, viewDir, _BaseColor, perceptualRoughness, _Metallic);
    BRDF brdf = GetBRDF(surface);
    int count = GetDirectionalLightCount();
    half3 color;
    ShadowData data = GetShadowData(position, depthView);
    for(int i = 0; i < count; i++)
    {
        Light light = GetMainLight(i);
        DirectionalShadowData shadowData = GetDirectionalShadowData(i, data);
        shadowData.strength *= data.strength;
        light.attenuation = GetDirectionalShadowAttenuation(shadowData, data, position, normal);
        color += PBRBaseRendering(brdf, surface, light);
    }
    return half4(color, surface.alpha);
}
#endif