Shader "Custom/Scan" {
	Properties{
		_MainColor("MainColor",Color)=(1,1,1,1)
		_HighLightingColor("HighLightingColor",Color)=(1,1,1,1)
		_Threshold("Threshold",Float)=2.0
		_MainTex("MainTex",2D)="white"{}
	}
	SubShader{
		Tags{"Queue"="Transparent" "RenderType"="Transparent"}
		Pass{
			Tags{"LightMode"="ForwardBase"}

			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include "UnityCG.cginc"

			//提前定义
			uniform sampler2D_float _CameraDepthTexture;

			 fixed4 _MainColor;
			 fixed4 _HighLightingColor;
			 float   _Threshold;
			 sampler2D  _MainTex;
			 float4         _MainTex_ST;

			 struct a2v{
				float4 vertex:POSITION;
				float4 texcoord:TEXCOORD0;
			 };

			 struct v2f{
				float4 pos:SV_POSITION;
				float4 projPos:TEXCOORD0;
				float2 uv:TEXCOORD1; 
			};

			v2f vert(a2v v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);
				o.projPos=ComputeScreenPos(o.pos);
				o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
				return o;
			}

			fixed4 frag(v2f i):SV_Target{
				fixed4 finalColor=_MainColor;
				float sceneZ=LinearEyeDepth(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD(i.projPos)));
				float partZ=i.projPos.z;
				float diff=min((abs(sceneZ-partZ))/_Threshold,1.0);
				finalColor=lerp(_HighLightingColor,_MainColor,diff)*tex2D(_MainTex,i.uv);

				return finalColor;
			}
			ENDCG
		}
	}
	FallBack "Transparent/VertexLit"
}
