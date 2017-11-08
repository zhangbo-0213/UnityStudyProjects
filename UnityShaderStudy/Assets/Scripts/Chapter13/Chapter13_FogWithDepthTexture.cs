using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Chapter13_FogWithDepthTexture :PostEffectsBase
{

    public Shader fogWithDepthShader;
    private Material fogMaterial;

    public Material material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogWithDepthShader, fogMaterial);
            return fogMaterial;
        }
    }

    private Camera myCamera;
    public Camera camera
    {
        get
        {
            if (myCamera == null)
                myCamera = GetComponent<Camera>();
            return myCamera;
        }
    }

    private Transform myTransform;

    public Transform cameraTransform
    {
        get
        {
            if (myTransform == null)
                myTransform = camera.transform;
            return myTransform;
        }
    }

    //定义模拟雾效的参数
    [Range(0.0f, 3.0f)]
    public float fogDensity = 1.0f;

    public Color fogColor = Color.white;
    public float fogStart = 0.0f;
    public float fogEnd = 2.0f;

    void OnEnable()
    {
        camera.depthTextureMode |=DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture src,RenderTexture dest)
    {
        if (material != null)
        {
            Matrix4x4 frustumCorners = Matrix4x4.identity;

            float fov = camera.fieldOfView;
            float near = camera.nearClipPlane;
            float far = camera.farClipPlane;
            float aspect = camera.aspect;

            float halfHeight = near*Mathf.Tan(fov*0.5f*Mathf.Deg2Rad);
            Vector3 toTop = cameraTransform.up*halfHeight;
            Vector3 toRight = cameraTransform.right*halfHeight*aspect;

            Vector3 topLeft = cameraTransform.forward*near + toTop - toRight;
            float scale = topLeft.magnitude/near;
            topLeft.Normalize();
            topLeft *= scale;

            Vector3 topRight = cameraTransform.forward*near + toTop + toRight;
            topRight.Normalize();
            topRight *= scale;

            Vector3 bottomLeft = cameraTransform.forward*near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            Vector3 bottomRight = cameraTransform.forward*near - toTop + toRight;
            bottomRight.Normalize();
            bottomRight *= scale;

            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            material.SetMatrix("_FrustumCornerRay", frustumCorners);
          
            material.SetFloat("_FogDensity", fogDensity);
            material.SetColor("_FogColor", fogColor);
            material.SetFloat("_FogStart", fogStart);
            material.SetFloat("_FogEnd", fogEnd);

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
