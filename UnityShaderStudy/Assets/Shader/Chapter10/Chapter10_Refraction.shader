// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Chapter10_Refraction" {
	Properties{
		_Color("Color",Color)=(1,1,1,1)
		_RefractionColor("Reflection Color",Color)=(1,1,1,1)
		_RefractionAmount("Reflection Amount",Range(0,1))=1
		_RefractionRatio("Refraction Ratio",Range(0.1,1))=0.5
		_Cubemap("Cubemap",Cube)="_Skybox"{}
	}
	SubShader{
		Pass{
			Tags{"LightMode"="ForwardBase"}

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fwdbase

				#include "Lighting.cginc"
				#include "AutoLight.cginc"

				fixed4 _Color;
				fixed4 _RefractionColor;
				float   _RefractionAmount;
				float   _RefractionRatio;
				samplerCUBE  _Cubemap;

				struct a2v{
					float4 vertex:POSITION;
					float3 normal:NORMAL;
				};

				struct v2f{
					float4 pos:SV_POSITION;
					float3 worldPos:TEXCOORD0;
					float3 worldNormal:TEXCOORD1;
					float3 worldViewDir:TEXCOORD2;
					float3 worldRefr:TEXCOORD3;
					SHADOW_COORDS(4)
				};

				v2f vert(a2v v){
					v2f o;
					o.pos=UnityObjectToClipPos(v.vertex);
					o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
					o.worldNormal=UnityObjectToWorldNormal(v.normal);
					o.worldViewDir=UnityWorldSpaceViewDir(o.worldPos);

					//将观察方向的反方向作为入射方向去计算折射方向
					o.worldRefr=refract(-normalize(o.worldViewDir),normalize(o.worldNormal),_RefractionRatio);

					TRANSFER_SHADOW	(o);
					return o;
				}
				fixed4 frag(v2f i):SV_Target{
					fixed3 worldNormal=normalize(i.worldNormal);
					fixed3 worldViewDir=normalize(i.worldViewDir);
					fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));

					fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
					fixed3 diffuse=_LightColor0.rgb*_Color.rgb*max(dot(worldNormal,worldLightDir),0);
					fixed3 refraction=texCUBE(_Cubemap,i.worldRefr).rgb*_RefractionColor.rgb;
					
					UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

					fixed3 color=ambient+lerp(diffuse,refraction,_RefractionAmount)*atten;

					return fixed4(color,1.0);
				}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
