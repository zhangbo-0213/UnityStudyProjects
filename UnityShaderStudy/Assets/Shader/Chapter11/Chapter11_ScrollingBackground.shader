Shader "Custom/Chapter11_ScrollingBackground" {
	Properties{
		_MainTex("Base Layer",2D)="white"{}
		_DetialTex("Second Layer",2D)="white"{}
		_ScrollX("Base Layer Scroll Speed",Float)=1.0
		_Scroll2X("Second Layer Scroll Speed",Float)=1.0
		_Multiplier("Layer Multiplier",Float)=1
	}
	SubShader{
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			sampler2D _MainTex;
			float4         _MainTex_ST;
			sampler2D _DetialTex;
			float4        _DetialTex_ST;
			float			_ScrollX;
			float			_Scroll2X;
			float			_Multiplier;

			struct a2v{
				float4 vertex:POSITION;
				float4 texcoord:TEXCOORD0;
			};

			struct v2f {
				float4 pos:SV_POSITION;
				float4 uv:TEXCOORD0;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);
				o.uv.xy=TRANSFORM_TEX(v.texcoord,_MainTex)+frac(float2(_ScrollX,0)*_Time.y);
				o.uv.zw=TRANSFORM_TEX(v.texcoord,_DetialTex)+frac(float2(_Scroll2X,0)*_Time.y);
				//frac取小数函数，使取样坐标在[0,1]范围内，背景连续重复滚动

				return o;
			}

			fixed4 frag(v2f i):SV_Target{
				fixed4 baseLayer=tex2D(_MainTex,i.uv.xy);
				fixed4 secondLayer=tex2D(_DetialTex,i.uv.zw);
				fixed4 c=lerp(baseLayer,secondLayer,secondLayer.a);

				c.rgb*=_Multiplier;

				return c;
			}
			ENDCG
		}
	}
	FallBack "VertexLit"
}
