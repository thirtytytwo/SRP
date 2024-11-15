using LRP.Runtime;
using UnityEngine;
using UnityEngine.Experimental.GlobalIllumination;
using UnityEngine.Rendering;

public partial class LRenderPipeline : RenderPipeline
{
    private CameraRenderer mRenderer = new CameraRenderer();

    private bool mUseDynamicBatching, mUseGPUInstancing, mAllowHDR;
    private int colorLUTResolution;
    private ShadowSettings mShadowSettings;
    private PostFXSettings mPostFXSettings;
    
    public LRenderPipeline(bool allowHDR, bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher, ShadowSettings shadowSettings, PostFXSettings postFXSettings, int lut)
    {
        mUseDynamicBatching = useDynamicBatching;
        mUseGPUInstancing = useGPUInstancing;
        mShadowSettings = shadowSettings;
        mPostFXSettings = postFXSettings;
        mAllowHDR = allowHDR;
        colorLUTResolution = lut;
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
        GraphicsSettings.lightsUseLinearIntensity = true;
        InitializeForEditor();
    }
    
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        for(int i = 0; i < cameras.Length; i++)
        {
            mRenderer.Render(context, cameras[i], mUseDynamicBatching, mUseGPUInstancing, mShadowSettings, mPostFXSettings, mAllowHDR, colorLUTResolution);
        }
    }

    partial void InitializeForEditor();
}
