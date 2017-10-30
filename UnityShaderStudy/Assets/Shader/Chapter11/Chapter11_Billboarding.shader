Shader "Custom/Chapter11_Billboarding" {
		Properties{
			_Color("Color",Color)=(1,1,1,1)
			_MainTex("MainTex",2D)="white"{}
			_VerticalBillboarding("VerticalBillboarding",Range(0,1))=1
		}
		SubShader{
			Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RendererType"="Transparent" "DisableBatching"="True"}
			Pass{
				Tags{"LightMode"="ForwardBase"}
				ZWrite Off
				Blend SrcAlpha OneMinusSrcAlpha
				Cull Off  
				CGPROGRAM 
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
				#include "Lighting.cginc"

				fixed4 _Color;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				float _VerticalBillboarding;

				struct a2v{
					float4 vertex:POSITION;
					float4 texcoord:TEXCOORD0;

				};
				struct v2f{
					float4 pos:SV_POSITION;
					float2 uv:TEXCOORD0;
				};

				v2f vert(a2v v){
					v2f o;
					float3 center=float3(0,0,0);
					//选择模型空间的原点作为变换锚点
					float3 viewer=mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
					//将模型空间的观察方向作为法线方向
					float3 normalDir=viewer-center;
					normalDir.y=normalDir.y*_VerticalBillboarding;
					normalDir=normalize(normalDir);
					//当_VerticalBillboarding的值为1时，法线方向固定为视角方向，
					//当_VerticalBillboarding的值为0时，法线在Y方向上没有分量，那么向上的方向固定为(0,1,0)，这样才能保证与法线方向垂直
					float3 upDir=abs(normalDir.y)>0.999 ? float3(0,0,1) : float3(0,1,0);
					//这里对向上方向是否与法向方向相平行，防止得到错误的叉乘结果
					float3 rightDir=normalize(cross(normalDir,upDir));
					upDir=normalize(cross(normalDir,rightDir));  

					float3 offset=v.vertex.xyz-center;
					float3 localPos=center+rightDir*offset.x+upDir*offset.y+normalDir*offset.z;  

					o.pos=UnityObjectToClipPos(float4(localPos,1));
					o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
					return o;

				}

				fixed4 frag(v2f i):SV_Target{
					fixed4 c=tex2D(_MainTex,i.uv);
					c.rgb*=_Color.rgb;
					return c;
				}
				ENDCG
			}
		}
		FallBack  "Transparent/VertexLit"
}
