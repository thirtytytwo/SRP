Shader "LRP/Lit"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _PerceptualRoughness ("Roughness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.5
        
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Blend [_SrcBlend] [_DstBlend]
        Pass
        {
            Tags {"LightMode" = "LRPLit"}
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex LitVertex
            #pragma fragment LitFragment

            #include "Assets/LRP/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float _Metallic;
            float _PerceptualRoughness;
            
            CBUFFER_END

            #include "Assets/LRP/ShaderLibrary/LitPass.hlsl"
            ENDHLSL
        }

		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			ColorMask 0

			HLSLPROGRAM
			#pragma target 4.5

			#pragma vertex ShadowCasterVertex
			#pragma fragment ShadowCasterFragment
			#include "Assets/LRP/ShaderLibrary/ShadowCasterPass.hlsl"
			ENDHLSL
		}
    }
}
