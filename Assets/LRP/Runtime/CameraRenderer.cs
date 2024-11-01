using UnityEngine;
using UnityEngine.Rendering;

namespace LRP.Runtime
{
    public partial class CameraRenderer
    {
        static ShaderTagId mUnlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
        static ShaderTagId mLitShaderTagId = new ShaderTagId("LRPLit");
        
        private ScriptableRenderContext mContext;

        private Camera mCamera;
        
        CommandBuffer mBuffer = new CommandBuffer {name = "Render Camera"};
        
        CullingResults mCullingResults;

        private Lighting Lighting = new Lighting();

#if UNITY_EDITOR
        private string mSampleName { get; set; }
#else
        const string mSampleName = mBuffer.name;
#endif
        
        public void Render(ScriptableRenderContext context, Camera camera, bool dynamic, bool instancing, ShadowSettings shadowSettings)
        {
            this.mContext = context;
            this.mCamera = camera;

            PrepareForSceneView();
            PrepareBuffer();
            if (!Cull(shadowSettings.MaxShadowDistance)) return;
            
            mBuffer.BeginSample(mSampleName);
            ExecuteBuffer();
            Lighting.Setup(context, mCullingResults, shadowSettings);
            mBuffer.EndSample(mSampleName);
            Setup();
            DrawVisibleGeometry(dynamic, instancing);
            DrawUnsupportedShaders();
            DrawGizmos();
            Lighting.Cleanup();
            Submit();
        }

        partial void PrepareForSceneView();
        partial void PrepareBuffer();
        
        void DrawVisibleGeometry(bool dynamic, bool instancing)
        {
            var sortingSettings = new SortingSettings(mCamera);
            var drawingSettings = new DrawingSettings(mUnlitShaderTagId, sortingSettings)
            {
                enableInstancing = instancing, 
                enableDynamicBatching = dynamic,
                perObjectData = PerObjectData.Lightmaps | PerObjectData.LightProbe 
                                                        | PerObjectData.LightProbeProxyVolume 
                                                        | PerObjectData.ShadowMask 
                                                        | PerObjectData.OcclusionProbe
                                                        | PerObjectData.OcclusionProbeProxyVolume
            };
            var filteringSettings = new FilteringSettings(RenderQueueRange.all);
            
            drawingSettings.SetShaderPassName(1, mLitShaderTagId);
            
            mContext.DrawRenderers(mCullingResults, ref drawingSettings, ref filteringSettings);
            
            mContext.DrawSkybox(mCamera);
        }
        partial void DrawGizmos();

        void Setup()
        {
            mContext.SetupCameraProperties(mCamera);
            CameraClearFlags flags = mCamera.clearFlags;
            mBuffer.ClearRenderTarget(
                flags <= CameraClearFlags.Depth,
                flags == CameraClearFlags.Color,
                flags == CameraClearFlags.Color ? mCamera.backgroundColor.linear : Color.clear
                );
            mBuffer.BeginSample(mSampleName);
            ExecuteBuffer();
        }
        void Submit()
        {
            mBuffer.EndSample(mSampleName);
            ExecuteBuffer();
            mContext.Submit();
        }
        void ExecuteBuffer()
        {
            mContext.ExecuteCommandBuffer(mBuffer);
            mBuffer.Clear();
        }

        bool Cull(float maxShadowDistance)
        {
            if (mCamera.TryGetCullingParameters(out ScriptableCullingParameters parameter))
            {
                parameter.shadowDistance = Mathf.Min(maxShadowDistance, mCamera.farClipPlane);
                mCullingResults = mContext.Cull(ref parameter);
                return true;
            }

            mCullingResults = default;
            return false;
        }
    }
}
