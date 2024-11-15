using UnityEngine;
using UnityEngine.Rendering;

namespace LRP.Runtime
{
    public partial class CameraRenderer
    {
        static ShaderTagId mUnlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
        static ShaderTagId mLitShaderTagId = new ShaderTagId("LRPLit");
        
        static int frameBufferId = Shader.PropertyToID("_CameraFrameBuffer");
        
        private ScriptableRenderContext mContext;

        private Camera mCamera;
        
        CommandBuffer mBuffer = new CommandBuffer {name = "Render Camera"};
        
        CullingResults mCullingResults;

        private Lighting Lighting = new Lighting();
        private PostFXStack postFXStack = new PostFXStack();

        private bool useHDR;

#if UNITY_EDITOR
        private string mSampleName { get; set; }
#else
        const string mSampleName = mBuffer.name;
#endif
        
        public void Render(ScriptableRenderContext context, Camera camera, bool dynamic, bool instancing, ShadowSettings shadowSettings, PostFXSettings postFXSettings, bool allowHDR, int lutRes)
        {
            this.mContext = context;
            this.mCamera = camera;

            PrepareForSceneView();
            PrepareBuffer();
            if (!Cull(shadowSettings.MaxShadowDistance)) return;
            useHDR = allowHDR && mCamera.allowHDR;
            mBuffer.BeginSample(mSampleName);
            ExecuteBuffer();
            Lighting.Setup(context, mCullingResults, shadowSettings);
            postFXStack.Setup(context, camera, postFXSettings, allowHDR, lutRes);
            mBuffer.EndSample(mSampleName);
            Setup();
            DrawVisibleGeometry(dynamic, instancing);
            DrawUnsupportedShaders();
            if(postFXStack.IsActive) postFXStack.Render(frameBufferId);
            DrawGizmos();
            Cleanup();
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
                                                        | PerObjectData.ReflectionProbes
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
            if (postFXStack.IsActive)
            {
                if (flags > CameraClearFlags.Color) flags = CameraClearFlags.Color;
                mBuffer.GetTemporaryRT(frameBufferId, mCamera.pixelWidth, mCamera.pixelHeight,32, FilterMode.Bilinear, 
                    useHDR ? RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default);
                mBuffer.SetRenderTarget(frameBufferId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            }
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

        void Cleanup()
        {
            Lighting.Cleanup();
            if (postFXStack.IsActive)
            {
                mBuffer.ReleaseTemporaryRT(frameBufferId);
            }
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
