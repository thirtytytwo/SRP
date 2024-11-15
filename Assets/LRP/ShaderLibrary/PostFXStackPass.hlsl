#ifndef L_POST_FX_PASS_INCLUDE
#define L_POST_FX_PASS_INCLUDE

#include "Assets/LRP/ShaderLibrary/UnityInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
struct Varying
{
    float4 positionCS : SV_POSITION;
    float2 screenUV : VAR_SCREEN_UV;
};

float4 _PostFXSource_TexelSize;
float4 _BloomThreshold;
float4 _ColorAdjustments;
float4 _ColorFilter;
float4 _WhiteBalance;
float4 _SplitToningShadows, _SplitToningHighlights;
float4 _ColorGradingLUTParameters;
float _BloomIntensity;

bool _ColorGradingLUTInLogC;

TEXTURE2D(_PostFXSource);
TEXTURE2D(_PostFXSource2);
TEXTURE2D(_ColorGradingLUT);
SAMPLER(sampler_LinearClamp);

Varying DefaultVertexPass(uint vertexID : SV_VertexID)
{
    Varying output;
    output.positionCS = float4(vertexID <= 1 ? -1.0 : 3.0, vertexID == 1 ? 3.0 : -1.0, 0, 1.0);
    output.screenUV = float2(vertexID <= 1 ? 0.0 : 2.0, vertexID == 1 ? 2.0 : 0.0);
    if(_ProjectionParams.x < 0.0) output.screenUV.y = 1.0 - output.screenUV.y;
    return output;
}

float4 GetSource(float2 screenUV)
{
    return SAMPLE_TEXTURE2D_LOD(_PostFXSource, sampler_LinearClamp, screenUV, 0);
}

float4 GetSource2(float2 screenUV)
{
    return SAMPLE_TEXTURE2D_LOD(_PostFXSource2, sampler_LinearClamp, screenUV, 0);
}

float4 GetSourceBicubic(float2 screenUV)
{
    return SampleTexture2DBicubic(TEXTURE2D_ARGS(_PostFXSource, sampler_LinearClamp), screenUV, _PostFXSource_TexelSize.zwxy, 1.0, 0.0);
}

float4 GetSourceTexelSize()
{
    return _PostFXSource_TexelSize;
}

float3 ColorGradePostExposure(float3 color)
{
    return color * _ColorAdjustments.x;
}
float3 ColorGradingContrast(float3 color)
{
    color = LinearToLogC(color);
    color = (color - ACEScc_MIDGRAY) * _ColorAdjustments.y + ACEScc_MIDGRAY;
    return LogCToLinear(color);
}
float3 ColorGradeColorFilter (float3 color) {
    return color * _ColorFilter.rgb;
}
float3 ColorGradingHueShift (float3 color) {
    color = RgbToHsv(color);
    float hue = color.x + _ColorAdjustments.z;
    color.x = RotateHue(hue, 0.0, 1.0);
    return HsvToRgb(color);
}
float3 ColorGradingSaturation (float3 color) {
    float luminance = Luminance(color);
    return (color - luminance) * _ColorAdjustments.w + luminance;
}
float3 ColorGradeWhiteBalance(float3 color)
{
    color = LinearToLMS(color);
    color *= _WhiteBalance.rgb;
    return LMSToLinear(color);
}
float3 ColorGradeSplitToning (float3 color) {
    color = PositivePow(color, 1.0 / 2.2);
    float t = saturate(Luminance(saturate(color)) + _SplitToningShadows.w);
    float3 shadows = lerp(0.5, _SplitToningShadows.rgb, 1.0 - t);
    float3 highlights = lerp(0.5, _SplitToningHighlights.rgb, t);
    color = SoftLight(color, shadows);
    color = SoftLight(color, highlights);
    return PositivePow(color, 2.2);
}
float3 ColorGrade(float3 color)
{
    color = min(color, 60.0);
    color = ColorGradePostExposure(color);
    color = ColorGradeWhiteBalance(color);
    color = ColorGradingContrast(color);
    color = ColorGradeColorFilter(color);
    color = max(0.,color);
    color = ColorGradingHueShift(color);
    color = ColorGradingSaturation(color);
    color = max(0.,color);
    return color;
}

float3 ApplyBloomThreshold (float3 color) {
    float brightness = Max3(color.r, color.g, color.b);
    float soft = brightness + _BloomThreshold.y;
    soft = clamp(soft, 0.0, _BloomThreshold.z);
    soft = soft * soft * _BloomThreshold.w;
    float contribution = max(soft, brightness - _BloomThreshold.x);
    contribution /= max(brightness, 0.00001);
    return color * contribution;
}

float4 CopyPassFragment(Varying input) : SV_TARGET
{
    return GetSource(input.screenUV);
}

float4 BloomPrefilterPassFragment (Varying input) : SV_TARGET {
    float3 color = ApplyBloomThreshold(GetSource(input.screenUV).rgb);
    return float4(color, 1.0);
}
float4 BloomPrefilterFirefliesPassFragment (Varying input) : SV_TARGET {
    float3 color = 0.0;
    float weightSum = 0.0;
    float2 offsets[] = {
        float2(0.0, 0.0),
        float2(-1.0, -1.0), float2(-1.0, 1.0), float2(1.0, -1.0), float2(1.0, 1.0)
    };
    for (int i = 0; i < 5; i++) {
        float3 c = GetSource(input.screenUV + offsets[i] * GetSourceTexelSize().xy * 2.0).rgb;
        c = ApplyBloomThreshold(c);
        float w = 1.0 / Luminance(c) + 1.0;
        weightSum += w;
        color += c * w;
    }
    color /= weightSum;
    return float4(color, 1.0);
}

float4 BloomHorizontalPassFragment (Varying input) : SV_TARGET {
    float3 color = 0.0;
    float offsets[] = {
        -4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0
    };
    float weights[] = {
        0.01621622, 0.05405405, 0.12162162, 0.19459459, 0.22702703,
        0.19459459, 0.12162162, 0.05405405, 0.01621622
    };
    for (int i = 0; i < 9; i++) {
        float offset = offsets[i] * 2.0 * GetSourceTexelSize().x;
        color += GetSource(input.screenUV + float2(offset, 0.0)).rgb * weights[i];
    }
    return float4(color, 1.0);
}

float4 BloomVerticalPassFragment (Varying input) : SV_TARGET {
    float3 color = 0.0;
    float offsets[] = {
        -3.23076923, -1.38461538, 0.0, 1.38461538, 3.23076923
    };
    float weights[] = {
        0.07027027, 0.31621622, 0.22702703, 0.31621622, 0.07027027
    };
    for (int i = 0; i < 5; i++) {
        float offset = offsets[i] * GetSourceTexelSize().y;
        color += GetSource(input.screenUV + float2(0.0, offset)).rgb * weights[i];
    }
    return float4(color, 1.0);
}

float4 BloomCombinePassFragment (Varying input) : SV_TARGET {
    float4 lowRes = GetSourceBicubic(input.screenUV);
    float4 highRes = GetSource2(input.screenUV);
    return float4((lowRes * _BloomIntensity + highRes).rgb, highRes.a);
}

float4 BloomScatterPassFragment (Varying input) : SV_TARGET {
    float3 lowRes = GetSourceBicubic(input.screenUV).rgb;
    float4 highRes = GetSource2(input.screenUV);
    return float4(lerp(highRes.rgb, lowRes, _BloomIntensity), highRes.a);
}

float3 GetColorGradedLUT (float2 uv) {
    float3 color = GetLutStripValue(uv, _ColorGradingLUTParameters);
    return ColorGrade(_ColorGradingLUTInLogC ? LogCToLinear(color) : color);
}
float4 ToneMappingReinhardPassFragment (Varying input) : SV_TARGET {
    float3 color = GetColorGradedLUT(input.screenUV);
    color = ColorGrade(color);
    color /= color + 1.0;
    return half4(color, 1.0);
}
float4 ToneMappingNeutralPassFragment (Varying input) : SV_TARGET {
    float3 color = GetColorGradedLUT(input.screenUV);
    color = ColorGrade(color);
    color = NeutralTonemap(color);
    return half4(color, 1.0);
}
float4 ToneMappingACESPassFragment (Varying input) : SV_TARGET {
    float3 color = GetColorGradedLUT(input.screenUV);
    color = ColorGrade(color);
    color = AcesTonemap(unity_to_ACES(color));
    return half4(color, 1.0);
}
float4 ToneMappingNonePassFragment (Varying input) : SV_TARGET {
    float3 color = GetColorGradedLUT(input.screenUV);
    color = ColorGrade(color);
    return half4(color, 1.0);
}
float3 ApplyColorGradingLUT (float3 color) {
    return ApplyLut2D(TEXTURE2D_ARGS(_ColorGradingLUT, sampler_LinearClamp), saturate(_ColorGradingLUTInLogC ? LinearToLogC(color) : color), _ColorGradingLUTParameters.xyz);
}

float4 FinalPassFragment (Varying input) : SV_TARGET {
    float4 color = GetSource(input.screenUV);
    color.rgb = ApplyColorGradingLUT(color.rgb);
    return color;
}
#endif