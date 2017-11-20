Shader "Custom/Chapter15_Dissolve" {
	Properties{
		_BurnAmount("Burn Amount",Range(0.0,1.0))=0.0
		_LineWidth("Burn Line Width",Range(0.0,0.2))=0.1
		_MainTex("MainTex",2D)="white"{}
		_BumpMap("Bump Map",2D)="bump"{}
		_BurnFirstColor("Burn First Color",Color)=(1,0,0,1)
		_BurnSecondColor("Burn Second Color",Color)=(1,0,0,1)
		_BurnMap("Burn Map",2D)="white"{}

		//_BurnAmount 用于控制消融的程度，值为0时为正常效果，值为1时物体完全消融
		//_LineWidth 控制模拟烧焦效果的线宽
		//_BurnFirstColor 和 _BurnSecondColor 对应火焰边缘两种颜色
		//_BurnMap 对应消融效果的噪声纹理
		}
		SubShader{
			Pass{
				Tags{"LightMode"="ForwardBase"}
				Cull Off  
				//关闭剔除功能，也就是说模型的正面和背面对会被渲染出来
				//这是由于消融效果会显示出物体内部的结构，因此背面的剔除需要关闭
				CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag

					#include "Lighting.cginc"
					#include "AutoLight.cginc"
					#pragma multi_compile_fwdbase

					fixed _BurnAmount;
					fixed _LineWidth;
					sampler2D _MainTex;
					float4 _MainTex_ST;
					sampler2D _BumpMap;
					float4 _BumpMap_ST;
					fixed4 _BurnFirstColor;
					fixed4 _BurnSecondColor;
					sampler2D _BurnMap;
					float4 _BurnMap_ST;

					struct a2v{
						float4 vertex:POSITION;
						float3 normal:NORMAL;
						float4 tangent:TANGENT;
						float4 texcoord:TEXCOORD0;
					};

					struct v2f{
						float4 pos:SV_POSITION;
						float2 uvMainTex:TEXCOORD0;
						float2 uvBumpMap:TEXCOORD1;
						float2 uvBurnMap:TEXCOORD2;
						float3 lightDir:TEXCOORD3;
						float3 worldPos:TEXCOORD4;

						SHADOW_COORDS(5)
					};

					v2f vert(a2v v){
						v2f o;
						o.pos=UnityObjectToClipPos(v.vertex);

						o.uvMainTex=TRANSFORM_TEX(v.texcoord,_MainTex);
						o.uvBumpMap=TRANSFORM_TEX(v.texcoord,_BumpMap);
						o.uvBurnMap=TRANSFORM_TEX(v.texcoord,_BurnMap);

						TANGENT_SPACE_ROTATION;
						o.lightDir=mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
						o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
						TRANSFER_SHADOW(o);

						return o;
					}

					fixed4 frag(v2f i):SV_Target{
						fixed3 burn=tex2D(_BurnMap,i.uvBurnMap);
						clip(burn.r-_BurnAmount);
						//通过噪声纹理的采样值与阈值比较来控制像素的剔除
						float3 tangentLightDir=normalize(i.lightDir);
						fixed3 tangentNormal=UnpackNormal(tex2D(_BumpMap,i.uvBumpMap));

						fixed3 albedo=tex2D(_MainTex,i.uvMainTex).rgb;
						fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
						fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(tangentLightDir,tangentNormal));

						fixed t=1-smoothstep(0.0,_LineWidth,burn.r-_BurnAmount);
						fixed3 burnColor=lerp(_BurnFirstColor,_BurnSecondColor,t);
						burnColor=pow(burnColor,5);
						//当t的值为1时，表明该像素点在消融边缘，t为0时，则为正常颜色
						//中间部分的插值模拟烧焦的痕迹，并使用pow函数

						UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
						fixed3 finalColor=lerp(ambient+diffuse*atten,burnColor,t*step(0.0001,_BurnAmount));
						
						return fixed4(finalColor,1.0);
					}
				ENDCG
			}

			//这里需要定义一个投射阴影的Shader，避免被剔除的区域投射阴影
			Pass{
				Tags{"LightMode"="ShadowCaster"}	
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_shadowcaster
				//用于投射阴影的Pass的LightMode要设置为ShadowCaster
				//同时需要使用 #pragma multi_compile_shadowcaster 编译指令
				#include "UnityCG.cginc"

				fixed _BurnAmount;
				sampler2D _BurnMap;
				float4 _BurnMap_ST;

				struct v2f{
					V2F_SHADOW_CASTER;
					//利用V2F_SHADOW_CASTER定义阴影投射需要定义的变量
					float2 uvBurnMap:TEXCOORD1;
				};

				v2f vert(appdata_base v){
					v2f o;
					TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
					//使用TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)填充
					//V2F_SHADOW_CASTER在背后声明的部分变量，由Unity去完成
					o.uvBurnMap=TRANSFORM_TEX(v.texcoord,_BurnMap);
					return o;
				}

				fixed4 frag(v2f i):SV_Target{
					fixed3 burn=tex2D(_BurnMap,i.uvBurnMap).rgb;
					clip(burn.r-_BurnAmount);
					SHADOW_CASTER_FRAGMENT(i)
					//根据噪声纹理将消融的像素剔除，剩下的通过内置宏由Unity去完成对应的阴影投射计算
				}
				ENDCG
			}
		}
		FallBack "DIFFUSE"
}
