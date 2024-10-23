#ifndef L_LIT_PASS_INCLUDE
#define L_LIT_PASS_INCLUDE

#include "Assets/LRP/ShaderLibrary/Core.hlsl"
#include "Assets/LRP/ShaderLibrary/Surface.hlsl"
#include "Assets/LRP/ShaderLibrary/Lighting.hlsl"

struct Attribute
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Varying
{
    float4 positionSS : SV_POSITION;
    float3 normalWS : TEXCOORD1;
    float2 uv : TEXCOORD0;
};

CBUFFER_START(UnityPerMaterial)
half4 _BaseColor;
CBUFFER_END

Varying LitVertex(Attribute input)
{
    Varying output;
    output.positionSS = TransformObjectToHClip(input.positionOS.xyz);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.uv = input.uv;
    return output;
}

half4 LitFragment(Varying input) : SV_Target
{
    Surface surface = GetSurface(input.normalWS, _BaseColor.rgb, _BaseColor.a);
    int count = GetDirectionalLightCount();
    half3 color;
    UNITY_LOOP
    for(int i = 0; i < count; i++)
    {
        Light light = GetMainLight(i);
        color += surface.color * light.color * saturate(dot(surface.normal, light.direction));
        color = saturate(color);
    }
    return half4(color, surface.alpha);
}
#endif