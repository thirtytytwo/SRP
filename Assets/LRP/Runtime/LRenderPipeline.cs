using LRP.Runtime;
using UnityEngine;
using UnityEngine.Rendering;

public class LRenderPipeline : RenderPipeline
{
    private CameraRenderer mRenderer = new CameraRenderer();

    private bool mUseDynamicBatching, mUseGPUInstancing;
    public LRenderPipeline(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher)
    {
        mUseDynamicBatching = useDynamicBatching;
        mUseDynamicBatching = useGPUInstancing;
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
    }
    
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        for(int i = 0; i < cameras.Length; i++)
        {
            mRenderer.Render(context, cameras[i], mUseDynamicBatching, mUseGPUInstancing);
        }
    }   
}
