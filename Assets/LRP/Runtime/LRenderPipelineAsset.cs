using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Serialization;

namespace LRP.Runtime
{
    [CreateAssetMenu(menuName = "Rendering/L Render Pipeline Asset", fileName = "RenderPipelineAsset")]
    public class LRenderPipelineAsset : RenderPipelineAsset
    {
        [SerializeField]
        bool m_UseDynamicBatch;

        [SerializeField]
        bool m_UseGPUInstancing;

        [SerializeField]
        bool m_useSRPBatcher;

        [SerializeField]
        bool m_AllowHDR;
        
        [SerializeField] 
        private ShadowSettings m_ShadowSettings = default;

        [SerializeField] 
        private PostFXSettings m_PostFXSettings = default;
        
        public enum ColorLUTResolution {_16 = 16, _32 = 32, _64 = 64 }
        
        [SerializeField] ColorLUTResolution m_ColorLUTResolution = ColorLUTResolution._32;

        protected override RenderPipeline CreatePipeline()
        {
            return new LRenderPipeline(m_AllowHDR, m_UseDynamicBatch, m_UseGPUInstancing, m_useSRPBatcher, m_ShadowSettings, m_PostFXSettings, (int)m_ColorLUTResolution);
        }
    }
}
