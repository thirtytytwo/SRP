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
            
            #include "Assets/LRP/ShaderLibrary/UnlitPass.hlsl"
            ENDHLSL
        }
    }
}
