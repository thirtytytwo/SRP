using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class Lighting
{
    const int maxDirLightCount = 4, maxOtherLightCount = 64;
    
    static int dirLightColorId = Shader.PropertyToID("_DirectionalLightColor");
    static int dirLightDirectionId = Shader.PropertyToID("_DirectionalLightDirection");
    static int dirLightCountId = Shader.PropertyToID("_DirectionalLightCount");
    static int dirLightShadowDataId = Shader.PropertyToID("_DirectionalLightShadowData");
    private static int
        otherLightCountId = Shader.PropertyToID("_OtherLightCount"),
        otherLightColorsId = Shader.PropertyToID("_OtherLightColors"),
        otherLightPositionsId = Shader.PropertyToID("_OtherLightPositions"),
        otherLightDirectionsId = Shader.PropertyToID("_OtherLightDirections"),
        otherLightSpotAnglesId = Shader.PropertyToID("_OtherLightSpotAngles");
    
    static Vector4[] dirLightColors = new Vector4[maxDirLightCount],
                     dirLightDirections = new Vector4[maxDirLightCount],
                     dirLightShadowData = new Vector4[maxDirLightCount];

    private static Vector4[] otherLightColors = new Vector4[maxOtherLightCount],
                             otherLightPositions = new Vector4[maxOtherLightCount],
                             otherLightDirections = new Vector4[maxOtherLightCount],
                             otherLightSpotAngles = new Vector4[maxOtherLightCount];
    
    
    private CommandBuffer buffer = new CommandBuffer() { name = "Lighting" };

    private CullingResults mCullingResults;
    
    private Shadow mShadow = new Shadow();

    public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSettings)
    {
        mCullingResults = cullingResults;
        buffer.BeginSample(buffer.name);
        mShadow.Setup(context, cullingResults, shadowSettings);
        SetupLight();
        mShadow.Render();
        buffer.EndSample(buffer.name);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
    
    private void SetupLight()
    {
        NativeArray<VisibleLight> visibleLights = mCullingResults.visibleLights;
        int dirLightCount = 0, otherLightCount = 0;
        for (int i = 0; i < visibleLights.Length; i++)
        {
            VisibleLight light = visibleLights[i];
            switch (light.lightType)
            {
                case LightType.Directional:
                    if (dirLightCount < maxDirLightCount)
                    {
                        dirLightColors[i] = light.finalColor;
                        dirLightDirections[i] = -light.localToWorldMatrix.GetColumn(2);
                        dirLightShadowData[i] = mShadow.ReserveDiectionalShadows(light.light, i);
                        dirLightCount++;
                    }
                    break;
                case LightType.Point:
                    if (otherLightCount < maxOtherLightCount)
                    {
                        otherLightColors[i] = light.finalColor;
                        Vector4 position = light.localToWorldMatrix.GetColumn(3);
                        position.w = 1f / Mathf.Max(light.range * light.range, 0.0001f);
                        otherLightPositions[i] = position;
                        otherLightCount++;
                    }
                    break;
                case LightType.Spot:
                    if (otherLightCount < maxDirLightCount)
                    {
                        otherLightColors[i] = light.finalColor;
                        Vector4 position = light.localToWorldMatrix.GetColumn(3);
                        position.w = 1f / Mathf.Max(light.range * light.range, 0.0001f);
                        float innerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * light.light.innerSpotAngle);
                        float outerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * light.spotAngle);
                        float angleRangeInv = 1f / Mathf.Max(innerCos - outerCos, 0.001f);
                        otherLightSpotAngles[i] = new Vector4(angleRangeInv, -outerCos * angleRangeInv);
                        otherLightPositions[i] = position;
                        otherLightDirections[i] = -light.localToWorldMatrix.GetColumn(2);
                        otherLightCount++;
                    }
                    break;
            }
        }
        
        buffer.SetGlobalInt(dirLightCountId, dirLightCount);
        if (dirLightCount > 0)
        {
            buffer.SetGlobalVectorArray(dirLightColorId, dirLightColors);
            buffer.SetGlobalVectorArray(dirLightDirectionId, dirLightDirections);
            buffer.SetGlobalVectorArray(dirLightShadowDataId, dirLightShadowData);
        }
        
        buffer.SetGlobalInt(otherLightCountId, otherLightCount);
        if (otherLightCount > 0)
        {
            buffer.SetGlobalVectorArray(otherLightColorsId, otherLightColors);
            buffer.SetGlobalVectorArray(otherLightPositionsId, otherLightPositions);
            buffer.SetGlobalVectorArray(otherLightDirectionsId, otherLightDirections);
            buffer.SetGlobalVectorArray(otherLightSpotAnglesId, otherLightSpotAngles);
        }
    }
    
    public void Cleanup()
    {
        mShadow.Cleanup();
    }  
}
