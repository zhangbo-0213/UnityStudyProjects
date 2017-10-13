Shader "Custom/Chapter10_Fresnel" {
	Properties{
		_Color("Color",Color)=(1,1,1,1)
		_FresnelFactor("FresnelFactor",Range(0,1))=0.5
		_FreractionRatio("FreractionRatio",Range(0.1,1))=0.5
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
			float   _FresnelFactor;
			float   _FreractionRatio;
			samplerCUBE _Cubemap;

			struct a2v{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
			};

			struct v2f{
				float4 pos:SV_POSITION;
				float3 worldPos	:TEXCOORD0;
				float3 worldNormal:TEXCOORD1;
				float3 worldViewDir:TEXCOORD2;
				float3 worldRefl:TEXCOORD3;
				float3 worldRefr:TEXCOORD4;
				SHADOW_COORDS(5)
			};

			v2f vert(a2v v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);
				o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
				o.worldNormal=UnityObjectToWorldNormal(v.normal);
				o.worldViewDir=UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefl=reflect(-o.worldViewDir,o.worldNormal);
				o.worldRefr=refract(-normalize(o.worldViewDir),normalize(o.worldNormal),_FreractionRatio);

				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f i):SV_Target{
				fixed3 worldNormal=normalize(i.worldNormal);
				fixed3 worldViewDir=normalize(i.worldViewDir);
				fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 diffuse=_LightColor0.rgb*_Color.rgb*max(dot(worldNormal,worldLightDir),0);
				fixed3 reflect=texCUBE(_Cubemap,i.worldRefl).rgb;

				fixed3 refract=texCUBE(_Cubemap,i.worldRefr).rgb;

				fixed fresnel=_FresnelFactor+(1-_FresnelFactor)*pow(1-dot(worldViewDir,worldNormal),5);
				
				UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

				//fixed3 color=ambient+lerp(diffuse,reflect,saturate(fresnel))*atten;
				fixed3 color=ambient+lerp(refract,reflect,saturate(fresnel))*atten;

				return fixed4(color,1.0);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
