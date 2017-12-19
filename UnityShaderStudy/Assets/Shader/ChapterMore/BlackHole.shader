﻿Shader "Custom/BlackHole" {
	Properties{
		_MainColor("MainColor",Color)=(1,1,1,1)
		_MainTex("MainTex",2D)="white"{}
		_BumpTex("BumpTex",2D)="bump"{}
		_BumpScale("BumpScale",Float)=1.0
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8.0,255))=20   

		//设置开始受影响的范围
       _Range("Range",Float)=5
	   //靠近黑洞位置的影响系数
	   _HoleAmount("HoleAmount",Range(1.0,2.0))=1.5
	}
	SubShader{
		Pass{
			Tags{"LightMode"="ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include "UnityCG.cginc"

			fixed4 _MainColor;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpTex;
			float4 _BumpTex_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			float _Range;
			half _HoleAmount; 
			float3 _BlackHolePos;

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
				//获得模型顶点在世界空间的位置
				float4 oriWorldPos=mul(unity_ObjectToWorld,v.vertex);
				//判断与黑洞的距离
				float dis=distance(oriWorldPos,_BlackHolePos);
				//设置变化后的新顶点，初始值为原顶点的世界空间坐标
				float4 worldPos=oriWorldPos;

				//该部分为原作者对顶点变换的判断过程

				//if(dis<_Range){
				//新的顶点位置在靠近黑洞的方向上受到的偏移影响，越靠近黑洞，偏移值越大
				//	worldPos.xyz+=normalize(_BlackHolePos-oriWorldPos)*(_Range-dis);
				//当变换后的顶点位置超出了黑洞位置时，该顶点位置即为黑洞位置，即完全被吞噬
				//这里是通过判断(worldPos-_BlackHolePos)和(_BlackHolePos-oriWorldPos)向量的方向
				//来确定是否超过黑洞，若同向则超过，其实自己动手画一下向量关系很直白
				//	if(dot((worldPos-_BlackHolePos),(_BlackHolePos-oriWorldPos))>0){
				//		worldPos.xyz=_BlackHolePos;
				//	}
				//}

				//该部分通过lerp函数来避免上面的两次if判断(if判断相对比较耗性能)
				//_HoleAmount系数是为了使靠近黑洞时受到的吞噬效果更加明显
				worldPos.xyz=lerp(oriWorldPos,_BlackHolePos,clamp((_Range-dis)*_HoleAmount/_Range,0,1));
				
				o.pos=mul(UNITY_MATRIX_VP,worldPos);
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

				fixed3 albedo=tex2D(_MainTex,i.uv.xy)*_MainColor.rgb;
				fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
				fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(tangentNormal,tangentLightDir));
				fixed3 halfDir=normalize(tangentLightDir+tangentViewDir);
				fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(saturate(dot(halfDir,tangentNormal)),_Gloss);

				return fixed4(ambient+diffuse+specular,1.0);
			}
			ENDCG
		}
	}
}
