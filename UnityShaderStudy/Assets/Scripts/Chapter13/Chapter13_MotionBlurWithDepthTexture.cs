using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Chapter13_MotionBlurWithDepthTexture : PostEffectsBase
{
    public Shader motionShader;
    private Material motionBlurMaterial = null;

    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    [Range(0.0f, 1.0f)]
    public float blurSize = 1.0f;
    //定义Camera类型变量，以获取该脚本所在的摄像机组件
    //得到摄像机位置，构建观察空间变换矩阵
    private Camera myCamera;
    public Camera camera
    {
        get
        {
            if (myCamera == null)
            {
                myCamera = GetComponent<Camera>();
            }      
            return myCamera;
        }
    }

    //定义一个保存上一帧视角*投影矩阵
    private Matrix4x4 previousViewProjectionMatrix;

    //定义摄像机状态，获取深度纹理
    void OnEable()
    {
        camera.depthTextureMode |=DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture src,RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_BlurSize", blurSize);

            material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
            Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix*camera.worldToCameraMatrix;
            Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
            material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
            previousViewProjectionMatrix = currentViewProjectionMatrix;

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
