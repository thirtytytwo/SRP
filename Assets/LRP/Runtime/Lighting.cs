using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class Lighting
{
    const int maxDirLightCount = 4;
    
    static int dirLightColorId = Shader.PropertyToID("_DirectionalLightColor");
    static int dirLightDirectionId = Shader.PropertyToID("_DirectionalLightDirection");
    static int dirLightCountId = Shader.PropertyToID("_DirectionalLightCount");
    
    static Vector4[] dirLightColors = new Vector4[maxDirLightCount],
                     dirLightDirections = new Vector4[maxDirLightCount];
    
    private CommandBuffer buffer = new CommandBuffer() { name = "Lighting" };

    private CullingResults mCullingResults;

    public void Setup(ScriptableRenderContext context, CullingResults cullingResults)
    {
        mCullingResults = cullingResults;
        buffer.BeginSample(buffer.name);
        SetupLight();
        buffer.EndSample(buffer.name);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
    
    private void SetupLight()
    {
        NativeArray<VisibleLight> visibleLights = mCullingResults.visibleLights;
        int dirLightCount = 0;
        for (int i = 0; i < visibleLights.Length; i++)
        {
            VisibleLight light = visibleLights[i];
            if(light.lightType != LightType.Directional) continue;
            dirLightColors[i] = light.finalColor;
            dirLightDirections[i] = -light.localToWorldMatrix.GetColumn(2);
            dirLightCount++;
            if(dirLightCount >= maxDirLightCount) break;
        }
        
        buffer.SetGlobalInt(dirLightCountId, dirLightCount);
        buffer.SetGlobalVectorArray(dirLightColorId, dirLightColors);
        buffer.SetGlobalVectorArray(dirLightDirectionId, dirLightDirections);
    }
}