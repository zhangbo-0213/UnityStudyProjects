Shader "Custom/Disturbance" {
	Properties{
		_MainTex("MainTex",2D)="white"{}
		_Mask("Mask",2D)="white"{}
		_Noise("Noise",2D)="white"{}
		_NoiseSpeedX("NoiseSpeedX",Range(0.0,3.0))=1.0
		_NoiseSpeedY("NoiseSpeedY",Range(0.0,3.0))=1.0
		_NoiseIntensity("NoiseIntensity",Range(0.0,3.0))=1.0
	}
	SubShader{
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Mask;
			float4 _Mask_ST;
			sampler2D _Noise;
			float4 _Noise_ST;
			half _NoiseSpeedX;
			half _NoiseSpeedY;
			half _NoiseIntensity;

			struct a2v{
				float4 vertex:POSITION;
				float2 texcoord:TEXCOORD0;
			};

			struct v2f{
				float4 pos:SV_POSITION;
				float2 uv1:TEXCOORD0;
				float2 uv2:TEXCOORD1;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);
				o.uv1=TRANSFORM_TEX(v.texcoord,_MainTex);
				o.uv2=TRANSFORM_TEX(v.texcoord,_Noise);

				return o;
			}

			//噪声纹理采样得到随机值并映射
			fixed2 SamplerFromNoise(float2 uv){
				float2 newUv=uv*_Noise_ST.xy+_Noise_ST.zw;
				fixed4 noiseColor=tex2D(_Noise,newUv);
				noiseColor=(noiseColor*2-1)*0.05;
				return noiseColor;
			}

			fixed4 frag(v2f i):SV_Target{
				//遮罩纹理采样
				fixed4 mask=tex2D(_Mask,i.uv1);
				//时间变量(t/20,t,2t,3t)
				float2 time=float2(_Time.x,_Time.x);
				//计算噪声偏移
				fixed2 noiseOffset=fixed2(0,0);
				noiseOffset=SamplerFromNoise(i.uv2+time*float2(_NoiseSpeedX,_NoiseSpeedY));
				//主纹理采样,使用噪声纹理控制扰动区域
				fixed4 mainColor=tex2D(_MainTex,i.uv1+noiseOffset*_NoiseIntensity*mask.r);
				
				return mainColor;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
