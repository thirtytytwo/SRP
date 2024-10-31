#ifndef L_META_PASS_INCLUDE
#define L_META_PASS_INCLUDE

#include "Assets/LRP/ShaderLibrary/Surface.hlsl"
#include "Assets/LRP/ShaderLibrary/Shadow.hlsl"
#include "Assets/LRP/ShaderLibrary/Lighting.hlsl"

struct Attribute
{
    float3 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
};

struct Varying
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
};

float unity_OneOverOutputBoost;
float unity_MaxOutputValue;
bool4 unity_MetaFragmentControl;

Varying MetaVertex(Attribute input)
{
    Varying output;
    input.positionOS.xy = input.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
    input.positionOS.z = input.positionOS.z > 0.0 ? FLT_MIN : 0.0;
    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    return output;
}

half4 MetaFragment(Varying input) : SV_Target
{
    float4 base = GetBase(input.uv);
    Surface surface;
    ZERO_INITIALIZE(Surface, surface);
    surface.color = base.rgb;
    surface.metallic = GetMetallic();
    surface.percetualRoughness = GetPerceptualRoughness();
    BRDF brdf = GetBRDF(surface);
    float4 meta = 0.0;
    if(unity_MetaFragmentControl.x)
    {
        meta = float4(brdf.diffuse, 1.0);
        meta.rgb += brdf.specular * brdf.roughness * 0.5;
        meta.rgb = min(PositivePow(meta.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
    }
    else if(unity_MetaFragmentControl.y)
    {
        meta = float4(GetEmission(input.uv), 1.0);
    }
    return meta;
}
#endif
