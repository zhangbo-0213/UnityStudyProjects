using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Chapter13_EdgeDetectNormalsAndDepth : PostEffectsBase
{
    public Shader edgeDetectShader;
    private Material edgeDetectMaterial;

    public Material material
    {
        get
        {
            edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }
    }

    [Range(0.0f, 1.0f)]
    public float edgeOnly = 0.0f;

    public Color edgeColor = Color.black;
    public Color backgroundColor = Color.white;

    //用于控制深度和法线纹理的采样距离，值越大，描边越宽
    public float sampleDistance = 1.0f;
    //灵敏值，影响领域的深度值或法线值相差多少时，会被认为存在一条边界
    public float sensitivityDepth = 1.0f;
    public float sensitivityNormals = 1.0f;

    void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |=DepthTextureMode.DepthNormals;
    }

    //默认情况下，OnRenderImage()会在所有的不透明和透明Pass执行完成后调用，以便对所有物体都产生影响
    //当希望在不透明物体的Pass完成后立即调用，不对透明物体产生影响，可以添加[ImageEffectOpaque]特性实现
    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture src,RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_EdgeOnly",edgeOnly);
            material.SetColor("_EdgeColor",edgeColor);
            material.SetColor("_BackgroundColor",backgroundColor);
            material.SetFloat("_SampleDistance",sampleDistance);
            material.SetVector("_Sensitivity",new Vector4(sensitivityNormals,sensitivityDepth,0.0f,0.0f));

            Graphics.Blit(src,dest,material);
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
