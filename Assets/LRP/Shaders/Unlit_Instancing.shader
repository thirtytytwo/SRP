Shader "LRP/Unlit_Instancing"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma vertex UnlitVertex
            #pragma fragment UnlitFragment

            #include "Assets/LRP/ShaderLibrary/Core.hlsl"

            struct Attribute
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varying
            {
                float4 positionSS : SV_POSITION;
                float2 uv : VAR_BASE_UV;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
            UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            Varying UnlitVertex(Attribute input)
            {
                Varying output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                output.positionSS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            half4 UnlitFragment(Varying input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                half4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
                return color;
            }
            ENDHLSL
        }
    }
}
