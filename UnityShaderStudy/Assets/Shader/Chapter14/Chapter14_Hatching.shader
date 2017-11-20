Shader "Custom/Chapter14_Hatching" {
	Properties{
		_Color("Color",Color)=(1,1,1,1)
		_TileFactor("Tile Factor",Float)=1
		_Outline("Outline",Range(0,1))=0.1
		_Hatch0("Hatch 0",2D)="white"{}
		_Hatch1("Hatch 1",2D)="white"{}
		_Hatch2("Hatch 2",2D)="white"{}
		_Hatch3("Hatch 3",2D)="white"{}
		_Hatch4("Hatch 4",2D)="white"{}
		_Hatch5("Hatch 5",2D)="white"{}

		//TileFactor为纹理的平铺系数，值越大，素描线条越密集
	}
	SubShader{
		Tags{"RenderType"="Opaque" "Queue"="Geometry"}
		UsePass "Custom/Chapter14_ToonShading/OUTLINE"  
		//素描风格往往也需要绘制轮廓线，使用之前的渲染轮廓Pass
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#pragma multi_compile_fwdbase

				#include "UnityCG.cginc"
				#include "AutoLight.cginc"

				fixed4 _Color;
				float _TileFactor;
				fixed _Outline;
				sampler2D _Hatch0;
				float4 _Hatch0_ST;
				sampler2D _Hatch1;
				float4 _Hatch1_ST;
				sampler2D _Hatch2;
				float4 _Hatch2_ST;
				sampler2D _Hatch3;
				float4 _Hatch3_ST;
				sampler2D _Hatch4;
				float4 _Hatch4_ST;
				sampler2D _Hatch5;
				float4 _Hatch5_ST;

				struct a2v{
					float4 vertex:POSITION;
					float3 normal:NORMAL;
					half4 texcoord:TEXCOORD0;
				};

				struct v2f{
					float4 pos:SV_POSITION;
					float2 uv:TEXCOORD0;
					fixed3 hatchWeight0:TEXCOORD1;
					fixed3 hatchWeight1:TEXCOORD2;
					float3 worldPos:TEXCOORD3;

					SHADOW_COORDS(4)

					//6个权重值分别存储在2个float3类型变量中
				};

				v2f vert(a2v v){
					v2f o;
					o.pos=UnityObjectToClipPos(v.vertex);
					o.uv=v.texcoord.xy*_TileFactor;
					//_TileFactor用来控制素描线条的密集程度（TEX的WrapMode为Repeat）
					
					float3 worldLightDir=normalize(WorldSpaceLightDir(v.vertex));
					float3 worldNormal=UnityObjectToWorldNormal(v.normal);
					float3 diff=max(0,dot(worldLightDir,worldNormal));
					//这里的关键便是通过计算漫反射系数来区分采样权重，并将权重与不同密集程度的TEX相对应

					o.hatchWeight0=fixed3(0,0,0);
					o.hatchWeight1=fixed3(0,0,0);

					//使用世界空间下的光照方向和法线方向得到漫反射系数
					//初始化权重值，*7分为7个区间，并根据hatchFactor的值，为权重赋值
					float hatchFactor=diff*7;
					if(hatchFactor>6){
						//不做任何赋值，保持纯白
					}
					else if(hatchFactor>5.0){
						o.hatchWeight0.x=hatchFactor-5.0;
					}
					else if(hatchFactor>4.0){
						o.hatchWeight0.x=hatchFactor-4.0;
						o.hatchWeight0.y=1.0-o.hatchWeight0.x;
					}
					else if(hatchFactor>3.0){
						o.hatchWeight0.y=hatchFactor-3.0;
						o.hatchWeight0.z=1.0-o.hatchWeight0.y;
					}
					else if(hatchFactor>2.0){
						o.hatchWeight1.x=hatchFactor-2.0;
					}
					else if(hatchFactor>1.0){
						o.hatchWeight1.x=hatchFactor-1.0;
						o.hatchWeight1.y=1.0-o.hatchWeight1.x;
					}
					else{
						o.hatchWeight1.y=hatchFactor;
						o.hatchWeight1.z=1.0-o.hatchWeight1.y;
					}

					o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;

					TRANSFER_SHADOW(o)

					return o;
				}
				fixed4 frag(v2f i):SV_Target{
					fixed4 hatchTex0=tex2D(_Hatch0,i.uv)*i.hatchWeight0.x;
					fixed4 hatchTex1=tex2D(_Hatch1,i.uv)*i.hatchWeight0.y;
					fixed4 hatchTex2=tex2D(_Hatch2,i.uv)*i.hatchWeight0.z;
					fixed4 hatchTex3=tex2D(_Hatch3,i.uv)*i.hatchWeight1.x;
					fixed4 hatchTex4=tex2D(_Hatch4,i.uv)*i.hatchWeight1.y;
					fixed4 hatchTex5=tex2D(_Hatch5,i.uv)*i.hatchWeight1.z;
					//得到6张素描纹理采样结果，并乘以对应的权重
					fixed4 whiteColor=fixed4(1,1,1,1)*(1.0-i.hatchWeight0.x-i.hatchWeight0.y-i.hatchWeight0.z-i.hatchWeight1.x-i.hatchWeight1.y-i.hatchWeight1.z);
					fixed4 hatchColor=hatchTex0+hatchTex1+hatchTex2+hatchTex3+hatchTex4+hatchTex5+whiteColor;
					//计算纯白的占比程度，素描风格中会有留白，使高光部分是白色
					UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

					return fixed4(hatchColor.rgb*_Color.rgb*atten,1.0);
					//混合各个颜色，并与衰减和模型颜色相乘得到最终颜色
				}
			ENDCG
		}
	}
	FallBack "Diffsue"
}
