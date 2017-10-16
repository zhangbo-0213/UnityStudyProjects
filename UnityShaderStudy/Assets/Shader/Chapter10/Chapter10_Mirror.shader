Shader "Custom/Chapter10_Mirror" {
	Properties{
		_MainTex("MainTex",2D)="white"{}
	}
	SubShader{
		
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "Lighting.cginc"

				sampler2D _MainTex;
				float4        _MainTex_ST;

				struct a2v{
					float4 vertex:POSITION;
					float4 texcoord:TEXCOORD0;
				};
				struct v2f{
					float4 pos:SV_POSITION;
					float4 uv:TEXCOORD0;
				};

				v2f vert(a2v v){
					v2f o;
					o.pos=UnityObjectToClipPos(v.vertex);
					o.uv=v.texcoord;
					o.uv.x=1-o.uv.x;   //将uv.x分量进行翻转，实现镜子效果

					return o;
				}
				fixed4 frag(v2f i):SV_Target{
					return tex2D(_MainTex,i.uv);
				}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
