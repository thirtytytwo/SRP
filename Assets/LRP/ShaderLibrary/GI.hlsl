#ifndef L_GI_INCLUDE
#define L_GI_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Assets/LRP/ShaderLibrary/UnityInput.hlsl"

TEXTURECUBE(unity_SpecCube0);
SAMPLER(samplerunity_SpecCube0);

TEXTURE2D(unity_Lightmap);
SAMPLER(samplerunity_Lightmap);

TEXTURE2D(unity_ShadowMask);
SAMPLER(samplerunity_ShadowMask);

TEXTURE3D_FLOAT(unity_ProbeVolumeSH);
SAMPLER(samplerunity_ProbeVolumeSH);

struct GI
{
    float3 diffuseIndir;
    float3 specularIndir;
    ShadowMask shadowMask;
};

float3 SampleLightmap(float2 uv)
{
    #ifdef LIGHTMAP_ON
        return SampleSingleLightmap(TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap), uv, float4(1.0, 1.0, 0, 0),
        #ifdef UNITY_LIGHTMAP_FULL_HDR
            false,
        #else
            true,
        #endif
        float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0, 0)
        );
    #else
        return 0.0f;
    #endif
}
float3 SampleLightProbe(Surface surface)
{
    #ifdef LIGHTMAP_ON
        return 0.f;
    #else
    if (unity_ProbeVolumeParams.x) {
        return SampleProbeVolumeSH4(
            TEXTURE3D_ARGS(unity_ProbeVolumeSH, samplerunity_ProbeVolumeSH),
            surface.position, surface.normal,
            unity_ProbeVolumeWorldToObject,
            unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
            unity_ProbeVolumeMin.xyz, unity_ProbeVolumeSizeInv.xyz
        );
    }
    else
    {
        float4 coefficients[7];
        coefficients[0] = unity_SHAr;
        coefficients[1] = unity_SHAg;
        coefficients[2] = unity_SHAb;
        coefficients[3] = unity_SHBr;
        coefficients[4] = unity_SHBg;
        coefficients[5] = unity_SHBb;
        coefficients[6] = unity_SHC;
        return max(0.0, SampleSH9(coefficients, surface.normal));
    }
    #endif
}
float4 SampleBakedShadows (float2 lightMapUV, Surface surface) {
    #if defined(LIGHTMAP_ON)
    return SAMPLE_TEXTURE2D(
        unity_ShadowMask, samplerunity_ShadowMask, lightMapUV
    );
    #else
    if (unity_ProbeVolumeParams.x) {
        return SampleProbeOcclusion(
            TEXTURE3D_ARGS(unity_ProbeVolumeSH, samplerunity_ProbeVolumeSH),
            surface.position, unity_ProbeVolumeWorldToObject,
            unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
            unity_ProbeVolumeMin.xyz, unity_ProbeVolumeSizeInv.xyz
        );
    }
    else {
        return unity_ProbesOcclusion;
    }
    #endif
}

float3 SampleEnvironment(Surface surface)
{
    float uvw = reflect(-surface.viewDirection, surface.normal);
    float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, 0);
    return environment.rgb;
} 

GI GetGI(float2 lightmapUV, Surface surface)
{
    GI gi;
    gi.diffuseIndir = SampleLightmap(lightmapUV) + SampleLightProbe(surface);
    gi.specularIndir = SampleEnvironment(surface);
    gi.shadowMask.distance = false;
    gi.shadowMask.shadows = 1.0;
    #if defined(_SHADOW_MASK_DISTANCE)
    gi.shadowMask.distance = true;
    gi.shadowMask.shadows = SampleBakedShadows(lightmapUV, surface);
    #endif
    return gi;
}
#endif