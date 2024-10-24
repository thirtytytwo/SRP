using LRP.Runtime;
using UnityEngine;
using UnityEngine.Rendering;

public class LRenderPipeline : RenderPipeline
{
    private CameraRenderer mRenderer = new CameraRenderer();

    private bool mUseDynamicBatching, mUseGPUInstancing;
    private ShadowSettings mShadowSettings;
    public LRenderPipeline(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher, ShadowSettings shadowSettings)
    {
        mUseDynamicBatching = useDynamicBatching;
        mUseGPUInstancing = useGPUInstancing;
        mShadowSettings = shadowSettings;
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
        GraphicsSettings.lightsUseLinearIntensity = true;
    }
    
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        for(int i = 0; i < cameras.Length; i++)
        {
            mRenderer.Render(context, cameras[i], mUseDynamicBatching, mUseGPUInstancing, mShadowSettings);
        }
    }   
}
