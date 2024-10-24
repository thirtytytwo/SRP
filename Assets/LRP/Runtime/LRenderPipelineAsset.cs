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
        private ShadowSettings m_ShadowSettings = default;

        protected override RenderPipeline CreatePipeline()
        {
            return new LRenderPipeline(m_UseDynamicBatch, m_UseGPUInstancing, m_useSRPBatcher, m_ShadowSettings);
        }
    }
}
