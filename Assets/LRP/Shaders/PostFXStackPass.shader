Shader "Unlit/PostFXStackPass"
{
    SubShader
    {
        Cull Off
        ZTest Always
        ZWrite Off
        
        HLSLINCLUDE
        #include "Assets/LRP/ShaderLibrary/Core.hlsl"
        #include "Assets/LRP/ShaderLibrary/PostFXStackPass.hlsl"
        ENDHLSL

        Pass
        {
            Name "Copy"
            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment CopyPassFragment
            ENDHLSL
        }
    }
}
