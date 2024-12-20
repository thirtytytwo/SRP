#ifndef L_UNITY_INPUT_INCLUDE
#define L_UNITY_INPUT_INCLUDE

CBUFFER_START(UnityPerDraw)
float4x4 unity_ObjectToWorld;
float4x4 unity_WorldToObject;
float4 unity_LODFade;
real4 unity_WorldTransformParams;

float4 unity_LightmapST;
float4 unity_DynamicLightmapST;

float4 unity_SHAr;
float4 unity_SHAg;
float4 unity_SHAb;
float4 unity_SHBr;
float4 unity_SHBg;
float4 unity_SHBb;
float4 unity_SHC;

float4 unity_ProbeVolumeParams;
float4x4 unity_ProbeVolumeWorldToObject;
float4 unity_ProbeVolumeSizeInv;
float4 unity_ProbeVolumeMin;

float4 unity_ProbesOcclusion;
float4 _ProjectionParams;
CBUFFER_END

float3 _WorldSpaceCameraPos;

float4x4 unity_MatrixVP;
float4x4 unity_MatrixV;
float4x4 unity_MatrixinvV;
float4x4 unity_prev_MatrixM;
float4x4 unity_prev_matrixIM;
float4x4 glstate_matrix_projection;

#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_PREV_MATRIX_M unity_prev_MatrixM
#define UNITY_PREV_MATRIX_I_M unity_prev_matrixIM
#define UNITY_MATRIX_P glstate_matrix_projection
#endif