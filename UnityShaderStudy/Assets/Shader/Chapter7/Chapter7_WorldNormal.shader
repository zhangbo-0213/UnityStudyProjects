// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Chapter7_WorldNormal" {
	Properties{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex("MainTex",2D) = "white"{}
		_BumpTex("BumpTex",2D) = "bump"{}
		_BumpScale("BumpScale",Float) = 1.0
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8.0,256)) = 20
	}

		SubShader{
			Pass{
				Tags{"LightMode" = "ForwardBase"}

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

				struct a2v {
					float4 vertex:POSITION;
					float3 normal:NORMAL;
					float4 tangent:TANGENT;
					float4 texcoord:TEXCOORD0;
				};  

				struct v2f {
					float4 pos:SV_POSITION;
					float4 uv:TEXCOORD0;
					//定义用于存储变换矩阵的变量，并拆分成行存储在对应行的变量中，
					//对于矢量的变换矩阵只需要3X3即可,float4的最后一个值可以用来存储世界空间下顶点的位置
					float4 T2W0:TEXCOORD1;
					float4 T2W1:TEXCOORD2;
					float4 T2W2:TEXCOORD3;
				};

				v2f vert(a2v v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv.xy = v.texcoord.xy*_MainTex_ST.xy + _MainTex_ST.zw;
					o.uv.zw = v.texcoord.xy*_BumpTex_ST.xy + _BumpTex_ST.zw;  

					float3 worldPos = mul(_Object2World, v.vertex).xyz;
					fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
					fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
					fixed3 worldBinormal = cross(worldNormal, worldTangent)*v.tangent.w;

					o.T2W0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x,worldPos.x);
					o.T2W1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
					o.T2W2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

					return o;
				}

				fixed4 frag(v2f i) :SV_Target{
					float3 worldPos = float3(i.T2W0.w,i.T2W1.w,i.T2W2.w);
					fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
					fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

					//法线纹理采样
					
					fixed3 tangentNormal = UnpackNormal(tex2D(_BumpTex, i.uv.zw));
					tangentNormal.xy *= _BumpScale;
					tangentNormal.z = sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));
			
					fixed3 worldNormal =normalize( half3(dot(i.T2W0.xyz,tangentNormal),dot(i.T2W1.xyz,tangentNormal),dot(i.T2W2.xyz,tangentNormal)));

					fixed3 albedo = _Color.rgb*tex2D(_MainTex,i.uv).rgb; 
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
					fixed3 diffuse = _LightColor0.rgb*albedo*max(0,dot(worldLightDir,worldNormal));
					fixed3 halfDir = normalize(worldLightDir+worldViewDir);
					fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(halfDir,worldNormal)),_Gloss);

					return fixed4(ambient+diffuse+specular,1.0);
				}
				ENDCG	
			}
		}
		FallBack "Specular"
}
