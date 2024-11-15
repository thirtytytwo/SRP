using System;
using UnityEngine;

[CreateAssetMenu(menuName = "Rendering/L Post FX Settings")]
public class PostFXSettings : ScriptableObject
{
    [SerializeField] 
    private Shader shader = default;
    
    [System.Serializable]
    public struct BloomSettings {

        [Range(0f, 16f)]
        public int maxIterations;

        [Min(1f)]
        public int downscaleLimit;
        
        [Min(0f)]
        public float threshold;

        [Range(0f, 1f)]
        public float thresholdKnee;

        [Range(0f, 2f)] 
        public float intensity;
        
        public bool fadeFireflies;
        
        public enum Mode { Additive, Scattering }

        public Mode mode;

        [Range(0f, 1f)]
        public float scatter;
    }

    [SerializeField]
    BloomSettings bloom = default;
    
    [System.Serializable]
    public struct ToneMappingSettings {

        public enum Mode { None, Reinhard, Neutral, ACES }

        public Mode mode;
    }

    [SerializeField]
    ToneMappingSettings toneMapping = default;

    [Serializable]
    public struct ColorAdjustmentsSettings
    {
        
        public float postExposure;

        [Range(-100f, 100f)]
        public float contrast;

        [ColorUsage(false, true)]
        public Color colorFilter;

        [Range(-180f, 180f)]
        public float hueShift;

        [Range(-100f, 100f)]
        public float saturation;
    }

    [SerializeField]
    ColorAdjustmentsSettings colorAdjustments = new ColorAdjustmentsSettings{colorFilter =  Color.white};
    [Serializable]
    public struct WhiteBalanceSettings {

        [Range(-100f, 100f)]
        public float temperature, tint;
    }

    [SerializeField]
    WhiteBalanceSettings whiteBalance = default;
    
    [Serializable]
    public struct SplitToningSettings {

        [ColorUsage(false)]
        public Color shadows, highlights;

        [Range(-100f, 100f)]
        public float balance;
    }

    [SerializeField]
    SplitToningSettings splitToning = new SplitToningSettings {
        shadows = Color.gray,
        highlights = Color.gray
    };

    public SplitToningSettings SplitToning => splitToning;

    public WhiteBalanceSettings WhiteBalance => whiteBalance;

    public ColorAdjustmentsSettings ColorAdjustments => colorAdjustments;

    public ToneMappingSettings ToneMapping => toneMapping;

    public BloomSettings Bloom => bloom;

    [System.NonSerialized]
    private Material material;

    public Material Material
    {
        get
        {
            if (material == null && shader != null)
            {
                material = new Material(shader);
                material.hideFlags = HideFlags.HideAndDontSave;
            }

            return material;
        }
    }
}
