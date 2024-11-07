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
    }

    [SerializeField]
    BloomSettings bloom = default;

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
