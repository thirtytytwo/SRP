using UnityEngine;
using UnityEngine.Rendering;

public enum Pass
{
    Copy
}
public partial class PostFXStack
{
    private const string bufferName = "Post FX";
    private const int maxBloomPyramidLevels = 16;

    private CommandBuffer buffer = new CommandBuffer { name = bufferName };

    private ScriptableRenderContext context;
    private Camera camera;
    private PostFXSettings settings;

    private int fxSouceId = Shader.PropertyToID("_PostFXSource");
    private int bloomPyramidId;

    public bool IsActive => settings != null;
    
    public PostFXStack () {
        bloomPyramidId = Shader.PropertyToID("_BloomPyramid0");
        for (int i = 1; i < maxBloomPyramidLevels; i++) {
            Shader.PropertyToID("_BloomPyramid" + i);
        }
    }
    public void Setup(ScriptableRenderContext context, Camera camera, PostFXSettings settings)
    {
        this.context = context;
        this.camera = camera;
        this.settings = camera.cameraType <= CameraType.SceneView ? settings : null;
        ApplySceneViewState();
    }

    public void Render(int sourceId)
    {
        DoBloom(sourceId);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    void Draw(RenderTargetIdentifier from, RenderTargetIdentifier to, Pass pass)
    {
        buffer.SetGlobalTexture(fxSouceId, from);
        buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        buffer.DrawProcedural(Matrix4x4.identity, settings.Material, (int)pass, MeshTopology.Triangles,3);
    }
    
    void DoBloom (int sourceId) {
        buffer.BeginSample("Bloom");
        PostFXSettings.BloomSettings bloom = settings.Bloom;
        int width = camera.pixelWidth / 2, height = camera.pixelHeight / 2;
        RenderTextureFormat format = RenderTextureFormat.Default;
        int fromId = sourceId, toId = bloomPyramidId;
        int i;
        for (i = 0; i < bloom.maxIterations; i++) {
            if (height < bloom.downscaleLimit || width < bloom.downscaleLimit) {
                break;
            }
            buffer.GetTemporaryRT(
                toId, width, height, 0, FilterMode.Bilinear, format
            );
            Draw(fromId, toId, Pass.Copy);
            fromId = toId;
            toId += 1;
            width /= 2;
            height /= 2;
        }
        Draw(fromId, BuiltinRenderTextureType.CameraTarget, Pass.Copy);
        
        for (i -= 1; i >= 0; i--) {
            buffer.ReleaseTemporaryRT(bloomPyramidId + i);
        }
        
        buffer.EndSample("Bloom");
    }
}
