Shader "Custom/Chapter11_Water" {
	Properties{
		_Color("Main Color",Color)=(1,1,1,1)
		_MainTex("MainTex",2D)="white"{}
		_Magnitude("Magnitude",Float)=1
		_Frequency("Frequency",Float)=1
		_InvWaveLength("InvWaveLength",Float)=10
		_Speed("Speed",Float)=0.5
	}
	SubShader{
	Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
			//为透明效果设置对应标签，这里“DisableBatching”的标签是关闭批处理，
			//包含模型空间顶点动画的Shader是需要特殊处理的Shader，
			//而批处理会合并所有相关的模型，这些模型各自的模型空间会丢失
			//而顶点动画需要在模型空间对顶点进行偏移
		Pass{
			Tags{"LightMode"="ForwardBase"}
			ZWrite Off
			Blend SrcAlpha OneMinusDstAlpha
			Cull Off
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "Lighting.cginc"
				#include "UnityCG.cginc"

				fixed4 _Color;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				float _Magnitude;
				float _Frequency;
				float _InvWaveLength;
				float _Speed;

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
					float4 offset;
					offset.yzw=float3(0.0,0.0,0.0);
					offset.x=sin(_Frequency*_Time.y+v.vertex.x*_InvWaveLength+v.vertex.y*_InvWaveLength+v.vertex.z*_InvWaveLength)*_Magnitude;
				    //在顶点进行空间变换前，对x分量进行正弦操作
					o.pos=UnityObjectToClipPos(v.vertex+offset);  

					o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
					o.uv+=float2(0.0,_Time.y*_Speed);
					//进行纹理动画

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
	FallBack "Transparent/VertexLit"
}
