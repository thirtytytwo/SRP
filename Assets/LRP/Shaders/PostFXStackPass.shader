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

        Pass
        {
            Name "Bloom Horizontal"
            
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment BloomHorizontalPassFragment
            ENDHLSL
        }

        Pass
        {
            Name "Bloom Vertical"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment BloomVerticalPassFragment
            ENDHLSL
        }

        Pass
        {
            Name "Bloom Combine"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment BloomCombinePassFragment
            ENDHLSL
        }

        Pass
        {
            Name "Bloom Prefilter"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment BloomPrefilterPassFragment
            ENDHLSL
        }
    }
}