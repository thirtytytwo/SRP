using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Profiling;

namespace LRP.Runtime
{
    public partial class CameraRenderer
    {
        
        static ShaderTagId mUnlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");

        static ShaderTagId[] mLegacyShaderTagIds =
        {
            new ShaderTagId("Always"),
            new ShaderTagId("ForwardBase"),
            new ShaderTagId("PrepassBase"),
            new ShaderTagId("Vertex"),
            new ShaderTagId("VertexLMRGBM"),
            new ShaderTagId("VertexLM")
        };

        static Material errorMaterial;

        void DrawUnsupportedShaders()
        {
            if (errorMaterial == null)
            {
                errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
            }

            var sortingSettings = new SortingSettings(mCamera);
            var drawingSettings = new DrawingSettings(mLegacyShaderTagIds[0], sortingSettings) { overrideMaterial = errorMaterial };
            for (int i = 1; i < mLegacyShaderTagIds.Length; i++)
            {
                drawingSettings.SetShaderPassName(i, mLegacyShaderTagIds[i]);
            }

            var filteringSettings = FilteringSettings.defaultValue;

            mContext.DrawRenderers(mCullingResults, ref drawingSettings, ref filteringSettings);
        }

#if UNITY_EDITOR
        partial void DrawGizmos()
        {
            if (UnityEditor.Handles.ShouldRenderGizmos())
            {
                mContext.DrawGizmos(mCamera, GizmoSubset.PreImageEffects);
                mContext.DrawGizmos(mCamera, GizmoSubset.PostImageEffects);
            }
        }
        
        partial void PrepareForSceneView()
        {
            if (mCamera.cameraType == CameraType.SceneView)
            {
                ScriptableRenderContext.EmitWorldGeometryForSceneView(mCamera);
            }
        }
        
        partial void PrepareBuffer()
        {
            Profiler.BeginSample("Editor Only");
            mBuffer.name = mSampleName = mCamera.name;
            Profiler.EndSample();
        }
        
#endif
    }
}
