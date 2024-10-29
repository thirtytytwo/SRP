using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ShadowSettings
{
    [Min(0.001f)] public float MaxShadowDistance = 100f;
    [Range(0.001f, 1f)] public float DistanceFade = 0.1f;
    
    [System.Serializable]
    public struct Directional
    {
        public ShadowMapSize _ShadowMapSize;
        public FilterMode _FilterMode;
        
        [Range(1,4)] public int _CascadeCount;
        [Range(0f, 1f)] public float _CascadeRatio1, _CascadeRatio2, _CascadeRatio3;
        [Range(0.001f, 1f)] public float _CascadeFade;
    }

    public Directional directional = new Directional()
    {
        _ShadowMapSize = ShadowMapSize._1024,
        _FilterMode =  FilterMode.PCF2X2,
        _CascadeCount = 4,
        _CascadeRatio1 = 0.1f,
        _CascadeRatio2 = 0.25f,
        _CascadeRatio3 = 0.5f,
        _CascadeFade = 0.1f
    };

    public enum ShadowMapSize
    {
        _256 = 256,
        _512 = 512,
        _1024 = 1024,
        _2048 = 2048,
        _4096 = 4096
    }
    
    public enum FilterMode
    {
        PCF2X2,
        PCF3X3,
        PCF5X5,
        PCF7X7
    }
    
}
