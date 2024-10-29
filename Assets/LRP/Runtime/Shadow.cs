using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class Shadow
{
    
    private CommandBuffer buffer = new CommandBuffer() { name = "Shadows" };

    private ScriptableRenderContext mContext;
    private CullingResults mCullingResults;
    private ShadowSettings mShadowSettings;

    private const int maxShadowDiectionalLightCount = 4, maxCascade = 4;

    private static int dirShadowAtlasId = Shader.PropertyToID("_DirectionalShadowAtlas"),
        dirShadowMatricesId = Shader.PropertyToID("_DirectionalShadowMatrices"),
        cascadeCountId = Shader.PropertyToID("_CascadeCount"),
        cascadeCullingSpheresId = Shader.PropertyToID("_CascadeCullingSpheres"),
        cascadeDataId = Shader.PropertyToID("_CascadeData"),
        shadosDistanceFadeId = Shader.PropertyToID("_ShadowDistance"),
        shadowAtlasSizeId = Shader.PropertyToID("_ShadowAtlasSize");
    static string[] directionalFilterKeywords = {
        "_DIRECTIONAL_PCF3",
        "_DIRECTIONAL_PCF5",
        "_DIRECTIONAL_PCF7",
    };
    
    static Vector4[] cascadeCullingSphere = new Vector4[maxCascade],
                        cascadeData = new Vector4[maxCascade];
    static Matrix4x4[] dirShadowMatrices = new Matrix4x4[maxShadowDiectionalLightCount * maxCascade];
    struct ShadowedDiectionalLight
    {
        public int visibleLightIndex;
        public float slopeScaleBias;
        public float nearPlaneOffset;
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

    public Vector3 ReserveDiectionalShadows(Light light, int visibleLightIndex)
    {
        if(shadowedDirectionalLightCount < maxShadowDiectionalLightCount && 
           light.shadows != LightShadows.None &&
           mCullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds bounds))
        {
            mShadowedDirectionalLights[shadowedDirectionalLightCount] = new ShadowedDiectionalLight {visibleLightIndex = visibleLightIndex, 
                                                                                                        slopeScaleBias = light.shadowBias, 
                                                                                                        nearPlaneOffset = light.shadowNearPlane};
            return new Vector3(light.shadowStrength, mShadowSettings.directional._CascadeCount * shadowedDirectionalLightCount++, light.shadowNormalBias);
        }
        
        return Vector2.zero;
    }

    private void RenderDirectionalShadows()
    {
        int atlasSize = (int)mShadowSettings.directional._ShadowMapSize;
        buffer.GetTemporaryRT(dirShadowAtlasId, atlasSize, atlasSize, 32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        buffer.SetRenderTarget(dirShadowAtlasId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        buffer.ClearRenderTarget(true, false, Color.clear);
        
        buffer.BeginSample(buffer.name);
        ExecuteBuffer();

        int tiles = shadowedDirectionalLightCount * mShadowSettings.directional._CascadeCount;
        int split = shadowedDirectionalLightCount <= 1 ? 1 : tiles <= 4 ? 2 : 4;
        int tileSize = atlasSize / split;
        for (int i = 0; i < shadowedDirectionalLightCount; i++)
        {
            RenderDirectionalShadows(i, split, tileSize);
        }

        float f = 1f - mShadowSettings.directional._CascadeFade;
        buffer.SetGlobalVector(shadosDistanceFadeId, new Vector4(1f / mShadowSettings.MaxShadowDistance, 1f / mShadowSettings.DistanceFade, 1f / (1f - f * f)));
        buffer.SetGlobalMatrixArray(dirShadowMatricesId, dirShadowMatrices);
        buffer.SetGlobalInt(cascadeCountId, mShadowSettings.directional._CascadeCount);
        buffer.SetGlobalVectorArray(cascadeCullingSpheresId, cascadeCullingSphere);
        buffer.SetGlobalVectorArray(cascadeDataId, cascadeData);
        buffer.SetGlobalVector(shadowAtlasSizeId, new Vector4(atlasSize, 1f / atlasSize));
        SetKeywords();
        buffer.EndSample(buffer.name);
        ExecuteBuffer();
    }

    private void RenderDirectionalShadows(int index,int split, int tileSize)
    {
        ShadowedDiectionalLight light = mShadowedDirectionalLights[index];
        var shadowSettings = new ShadowDrawingSettings(mCullingResults, light.visibleLightIndex);

        int cascadeCount = mShadowSettings.directional._CascadeCount;
        int tileOffset = index * cascadeCount;
        Vector3 ratios = new Vector3(mShadowSettings.directional._CascadeRatio1, mShadowSettings.directional._CascadeRatio2, mShadowSettings.directional._CascadeRatio3);

        for (int i = 0; i < cascadeCount; i++)
        {
            mCullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(
                light.visibleLightIndex, i, cascadeCount, ratios, tileSize, light.nearPlaneOffset,
                out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix,
                out ShadowSplitData splitData
            );
            shadowSettings.splitData = splitData;
            if (index == 0)
            {
                SetCascadeData(i, splitData.cullingSphere, tileSize);
            }
            int tileIndex = tileOffset + i;
            Vector2 offset = SetTileViewport(tileIndex, split, tileSize);
            dirShadowMatrices[tileIndex] = ConvertToAtlasMatrix(projectionMatrix * viewMatrix, offset, split);
            buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
            buffer.SetGlobalDepthBias(0f, light.slopeScaleBias);
            ExecuteBuffer();
            mContext.DrawShadows(ref shadowSettings);
            buffer.SetGlobalDepthBias(0f, 0f);
            
        }
    }

    private Vector2 SetTileViewport(int index, int split, float tileSize)
    {
        Vector2 offset = new Vector2(index % split, index / split);
        buffer.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));
        return offset;
    }
    
    void SetCascadeData (int index, Vector4 cullingSphere, float tileSize) {
        float texelSize = 2f * cullingSphere.w / tileSize;
        cullingSphere.w *= cullingSphere.w;
        cascadeData[index] = new Vector4(1f / cullingSphere.w, texelSize * 1.4142136f);
        cascadeCullingSphere[index] = cullingSphere;
    }

    private Matrix4x4 ConvertToAtlasMatrix(Matrix4x4 m, Vector2 offset, int split)
    {
        if (SystemInfo.usesReversedZBuffer)
        {
            m.m20 = -m.m20;
            m.m21 = -m.m21;
            m.m22 = -m.m22;
            m.m23 = -m.m23;
        }
        
        //说实话，这个地方0.5 * 00 和 30，不懂
        //文章说是 -1 到 1 转换 为 0 到 1 可以采样贴图
        //但不知道加了偏移值*0.5就是转换了是啥意思
        float scale = 1f / split;
        m.m00 = (0.5f * (m.m00 + m.m30) + offset.x * m.m30) * scale;
        m.m01 = (0.5f * (m.m01 + m.m31) + offset.x * m.m31) * scale;
        m.m02 = (0.5f * (m.m02 + m.m32) + offset.x * m.m32) * scale;
        m.m03 = (0.5f * (m.m03 + m.m33) + offset.x * m.m33) * scale;
        m.m10 = (0.5f * (m.m10 + m.m30) + offset.y * m.m30) * scale;
        m.m11 = (0.5f * (m.m11 + m.m31) + offset.y * m.m31) * scale;
        m.m12 = (0.5f * (m.m12 + m.m32) + offset.y * m.m32) * scale;
        m.m13 = (0.5f * (m.m13 + m.m33) + offset.y * m.m33) * scale;
        m.m20 = 0.5f * (m.m20 + m.m30);
        m.m21 = 0.5f * (m.m21 + m.m31);
        m.m22 = 0.5f * (m.m22 + m.m32);
        m.m23 = 0.5f * (m.m23 + m.m33);

        return m;
    }

    private void SetKeywords()
    {
        int enabledIndex = (int)mShadowSettings.directional._FilterMode - 1;
        for (int i = 0; i < directionalFilterKeywords.Length; i++) {
            if (i == enabledIndex) {
                buffer.EnableShaderKeyword(directionalFilterKeywords[i]);
            }
            else {
                buffer.DisableShaderKeyword(directionalFilterKeywords[i]);
            }
        }
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
