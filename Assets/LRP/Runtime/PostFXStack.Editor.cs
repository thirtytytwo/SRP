using UnityEngine;
using UnityEditor;

public partial class PostFXStack
{
    partial void ApplySceneViewState();
    
    #if UNITY_EDITOR
    partial void ApplySceneViewState()
    {
        if (camera.cameraType == CameraType.SceneView)
        {
            this.settings = null;
        }
    }
    #endif
}
