using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class Shadow
{
    
    private CommandBuffer buffer = new CommandBuffer() { name = "Shadows" };

    private ScriptableRenderContext mContext;
    private CullingResults mCullingResults;
    private ShadowSettings mShadowSettings;

    private const int maxShadowDiectionalLightCount = 4;
    
    static int dirShadowAtlasId = Shader.PropertyToID("_DirectionalShadowAtlas");

    struct ShadowedDiectionalLight
    {
        public int visibleLightIndex;
    }
    
    ShadowedDiectionalLight[] mShadowedDirectionalLights = new ShadowedDiectionalLight[maxShadowDiectionalLightCount];
    
    int shadowedDirectionalLightCount;

    public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSettings)
    {
        mContext = context;
        mShadowSettings = shadowSettings;
        mCullingResults = cullingResults;
        shadowedDirectionalLightCount = 0;
    }

    public void Render()
    {
        if (shadowedDirectionalLightCount > 0)
        {
            RenderDirectionalShadows();    
        }
        else
        {
            buffer.GetTemporaryRT(dirShadowAtlasId, 1, 1, 32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        }
    }

    public void ReserveDiectionalShadows(Light light, int visibleLightIndex)
    {
        if(shadowedDirectionalLightCount < maxShadowDiectionalLightCount && 
           light.shadows != LightShadows.None &&
           mCullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds bounds))
        {
            mShadowedDirectionalLights[shadowedDirectionalLightCount] = new ShadowedDiectionalLight {visibleLightIndex = visibleLightIndex};
            shadowedDirectionalLightCount++;
        }
    }

    public void RenderDirectionalShadows()
    {
        int atlasSize = (int)mShadowSettings.directional._ShadowMapSize;
        buffer.GetTemporaryRT(dirShadowAtlasId, atlasSize, atlasSize, 32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        buffer.SetRenderTarget(dirShadowAtlasId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        buffer.ClearRenderTarget(true, false, Color.clear);
        
        buffer.BeginSample(buffer.name);
        ExecuteBuffer();

        int split = shadowedDirectionalLightCount <= 1 ? 1 : 2;
        int tileSize = atlasSize / split;
        for (int i = 0; i < shadowedDirectionalLightCount; i++)
        {
            RenderDirectionalShadows(i, split, tileSize);
        }
        
        buffer.EndSample(buffer.name);
        ExecuteBuffer();
    }

    private void RenderDirectionalShadows(int index,int split, int tileSize)
    {
        ShadowedDiectionalLight light = mShadowedDirectionalLights[index];
        var shadowSettings = new ShadowDrawingSettings(mCullingResults, light.visibleLightIndex);
        mCullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(
            light.visibleLightIndex, 0, 1, Vector3.zero, tileSize, 0f,
            out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix,
            out ShadowSplitData splitData
        );
        shadowSettings.splitData = splitData;
        SetTileViewport(index, split, tileSize);
        buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
        ExecuteBuffer();
        mContext.DrawShadows(ref shadowSettings);
    }

    private void SetTileViewport(int index, int split, float tileSize)
    {
        Vector2 offset = new Vector2(index % split, index / split);
        buffer.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));
    }

    void ExecuteBuffer()
    {
        mContext.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    public void Cleanup()
    {
        buffer.ReleaseTemporaryRT(dirShadowAtlasId);
        ExecuteBuffer();
    }
}
