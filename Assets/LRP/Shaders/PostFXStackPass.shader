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
        Pass
        {
            Name "Bloom Prefilter Fireflies"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment BloomPrefilterFirefliesPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Bloom Scatter"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment BloomScatterPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Final"
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment FinalPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "None Tone Mapping"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment ToneMappingNonePassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Tone Mapping Reinhard"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment ToneMappingReinhardPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Tone Mapping Netural"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment ToneMappingNeutralPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Tone Mapping ACES"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultVertexPass
            #pragma fragment ToneMappingACESPassFragment
            ENDHLSL
        }
    }
}