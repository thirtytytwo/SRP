using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ShadowSettings
{
    [Min(0.0f)] public float MaxShadowDistance = 100f;
    
    [System.Serializable]
    public struct Directional
    {
        public ShadowMapSize _ShadowMapSize;
    }

    public Directional directional = new Directional() { _ShadowMapSize = ShadowMapSize._1024 };

    public enum ShadowMapSize
    {
        _256 = 256,
        _512 = 512,
        _1024 = 1024,
        _2048 = 2048,
        _4096 = 4096
    }
    
}
