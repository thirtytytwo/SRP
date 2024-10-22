Shader "LRP/Unlit"
{
    Properties{}
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex UnlitVertex
            #pragma fragment UnlitFragment

            #include "Assets/LRP/ShaderLibrary/Core.hlsl"

            struct Attribute
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varying
            {
                float4 positionSS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varying UnlitVertex(Attribute input)
            {
                Varying varying;
                varying.positionSS = TransformObjectToHClip(input.positionOS.xyz);
                varying.uv = input.uv;
                return varying;
            }

            half4 UnlitFragment(Varying input) : SV_Target
            {
                half4 color = half4(1, 1, 1, 1);
                return color;
            }
            ENDHLSL
        }
    }
}
