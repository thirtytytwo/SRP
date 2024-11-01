Shader "LRP/Lit"
{
    Properties
    {
    	_BaseMap("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
    	[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,0)
        _PerceptualRoughness ("Roughness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.5
        
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
    }
    SubShader
    {
    	HLSLINCLUDE
    	#include "Assets/LRP/ShaderLibrary/Core.hlsl"
    	#include "Assets/LRP/ShaderLibrary/LitInput.hlsl"
    	ENDHLSL
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

            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ _SHADOW_MASK_DISTANCE

            #include "Assets/LRP/ShaderLibrary/LitPass.hlsl"
            ENDHLSL
        }

		Pass {
			Tags { "LightMode" = "ShadowCaster"}

			ColorMask 0

			HLSLPROGRAM
			#pragma target 4.5

			#pragma vertex ShadowCasterVertex
			#pragma fragment ShadowCasterFragment
			#include "Assets/LRP/ShaderLibrary/ShadowCasterPass.hlsl"
			ENDHLSL
		}
		Pass
		{
			Tags {"LightMode" = "Meta"}
			
			Cull Off
			
			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex MetaVertex
			#pragma fragment MetaFragment

			#include "Assets/LRP/ShaderLibrary/MetaPass.hlsl"
			ENDHLSL
		}
    }
}
