// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/Chapter6_DiffuseHalfLambert" {
	
	Properties{
		_Diffuse("DiffuseColor",Color) = (1.0,1.0,1.0,1.0)
	}

		SubShader{
		Pass{
		//定义光照模式，只有正确定光照模式，才能得到一些Unity内置光照变量
		Tags{ "LightMode" = "ForwardBase" }

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		//使用Unity的内置包含文件，使用其内置变量
		#include "Lighting.cginc"

		//定义与属性相同类型和相同名称的变量
		fixed4 _Diffuse;
		//定义顶点着色器输入结构体
	struct a2v {
		float4 vertex:POSITION;
		float3 normal:NORMAL;
	};
		//定义顶点着色器输出结构体（片元着色器输入结构体）
	struct v2f {
		float4 pos:SV_POSITION;
		float3 worldNormal:TEXCOORD0;
	};

	v2f vert(a2v v) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		//存储世界空间下的法线，传递给片元着色器
		o.worldNormal =mul(v.normal,unity_WorldToObject);
		return o;
	}

	fixed4 frag(v2f i) :SV_Target{
		fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
		fixed3 worldNormal = normalize(i.worldNormal);
		fixed3 worldLight = normalize(_WorldSpaceLightPos0);

		fixed halfLambert = dot(worldNormal, worldLight)*0.5 + 0.5;
		fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*halfLambert;

		fixed3 color = diffuse + ambient;
		return fixed4(color,1.0);
	}

		ENDCG
	}

	}
		Fallback"Diffuse"
}
