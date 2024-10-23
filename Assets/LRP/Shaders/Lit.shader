Shader "LRP/Lit"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {"LightMode" = "LRPLit"}
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex LitVertex
            #pragma fragment LitFragment

            #include "Assets/LRP/ShaderLibrary/LitPass.hlsl"
            ENDHLSL
        }
    }
}
