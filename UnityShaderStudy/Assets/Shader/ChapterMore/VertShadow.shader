Shader "Custom/VertShadow" {
	Properties {
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_BumpTex("BumpTex",2D)="bump"{}
		_BumpScale("BumpScale",Float)=1.0
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8.0,256))=20

		_LightDir("LightPos&PlaneHeight",vector)=(0,0,0,0)  //这里使用Float4类型变量存储场景中的光源位置和地面高度
		_ShadowColor("ShadowColor",Color)=(0,0,0,1)
		_ShadowFalloff("ShadowFalloff",Float)=1.0
	}
	SubShader {
	    //第一个Pass正常渲染模型
		Pass{
			Tags{"LightMode"="ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpTex;
			float4 _BumpTex_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
				float4 texcoord:TEXCOORD0;
			};

			struct v2f{
				float4 pos:SV_POSITION;
				float4 uv:TEXCOORD0;
				float3 lightDir:TEXCOORD1;
				float3 viewDir:TEXCOORD2;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);
				o.uv.xy=TRANSFORM_TEX(v.texcoord,_MainTex);
				o.uv.zw=TRANSFORM_TEX(v.texcoord,_BumpTex);

				float3 biNormal=cross(normalize(v.normal),normalize(v.tangent.xyz))*v.tangent.w;
				float3x3 rotation=float3x3(v.tangent.xyz,biNormal,v.normal);

				o.lightDir=mul(rotation,ObjSpaceLightDir(v.vertex).xyz);
				o.viewDir=mul(rotation,ObjSpaceViewDir(v.vertex).xyz);

				return o;
			}

			fixed4 frag(v2f i):SV_Target{
				fixed3 tangentLightDir=normalize(i.lightDir);
				fixed3 tangentViewDir=normalize(i.viewDir);

				fixed3 tangentNormal=UnpackNormal(tex2D(_BumpTex,i.uv.zw));
				tangentNormal.xy*=_BumpScale;
				tangentNormal.z=sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

				fixed3 albedo=_Color.rgb*tex2D(_MainTex,i.uv.xy);
				fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
				fixed3 diffuse = _LightColor0.rgb*albedo*max(0,dot(tangentNormal,tangentLightDir));
				fixed3 halfDir=normalize(tangentLightDir+tangentViewDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(tangentNormal,halfDir)),_Gloss);

				return fixed4(ambient+diffuse+specular,1.0);
			}
			ENDCG
		}
					//第二个Pass计算世界空间下顶点的的阴影投影点
			Pass{
				//设置透明混合模式
				Blend SrcAlpha OneMinusSrcAlpha
				//关闭深度写入
				ZWrite off
				//深度偏移防止阴影与地面穿插
				Offset -1,0

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				float4 _LightDir;
				float4 _ShadowColor;
				float4 _ShadowFalloff;

				struct a2v{
					float4 vertex:POSITION;
				};

				struct v2f{
					float4 pos:SV_POSITION;
					float4 color:COLOR;
				};

				//计算阴影投影点
				float3 ShadowProjectPos(float4 vertexPos){
					float3 shadowPos;
					//计算顶点的世界空间坐标
					float3 worldPos=mul(unity_ObjectToWorld,vertexPos).xyz;

					//灯光方向
					float3 lightDir=normalize(_LightDir.xyz);

					//计算阴影的世界空间坐标(如果顶点低于地面，则阴影点实际就是顶点在世界空间的位置，不做改变)
					shadowPos.y=min(worldPos.y,_LightDir.w);
					shadowPos.xz=worldPos.xz-lightDir.xz*max(0,worldPos.y-_LightDir.w)/(lightDir.y-_LightDir.w);

					return shadowPos;
				}

				v2f vert(a2v v){
					v2f o;

					//得到阴影的世界空间坐标
					float3 shadowPos=ShadowProjectPos(v.vertex);
					
					//将阴影点转换到裁剪空间
					o.pos=UnityWorldToClipPos(shadowPos);

					//得到模型在世界空间地面投影点的位置，然后与地面上的阴影点计算距离算衰减
					float3 center=float3(unity_ObjectToWorld[0].w,_LightDir.w,unity_ObjectToWorld[2].w);
					//这里的unity_ObjectToWorld矩阵前三行的最后一个分量存储的是子对象在父空间下的坐标位置
					float falloff=1-saturate(distance(shadowPos,center)*_ShadowFalloff);

					o.color=_ShadowColor;
					o.color.a*=falloff;

					return o;
				}

				fixed4 frag(v2f i):SV_Target{
					return i.color;
				}
				
				ENDCG
			}
		}		
}