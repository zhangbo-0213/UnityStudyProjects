Shader "Custom/Chapter10_GlassRefraction" {
	Properties{
		_MainTex("Main Tex",2D)="white"{}
		_BumpTex("Bump Tex",2D)="bump"{}
		_CubeMap("Cube Map",Cube)="_Skybox"{}
		_Distortion("Distortion",Range(0,100))=10
		_RefractAmount("Refract Amount",Range(0.0,1.0))=1.0
	}
	SubShader{
		Tags{"Queue"="Transparent" "RenderType"="Opaque"}
		//指定渲染队列为"Transparent"，确保所有不透明物体先渲染完成
		GrabPass {"_RefractionTex"}
		//声明GrabPass 该Pass会将屏幕抓取图像存储到名为"_RefractionTex"的纹理中
		Pass{
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag 

				#include "UnityCG.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;
				sampler2D _BumpTex;
				float4 _BumpTex_ST;
				samplerCUBE _CubeMap;
				float _Distortion;
				float _RefractAmount;
				sampler2D _RefractionTex;   //存储GrabPass抓取的屏幕图像
				float4 _RefractionTex_TexelSize;  //得到屏幕图像的纹素值，在做偏移计算时使用

				struct a2v{
					float4 vertex:POSITION;
					float3 normal:NORMAL;
					float4 tangent:TANGENT;
					float4 texcoord:TEXCOORD0;
				};

				struct v2f{
					float4 pos:SV_POSITION;
					float4 uv:TEXCOORD0;
					float4 scrPos:TEXCOORD1;
					float4 TtoW0:TEXCOORD2;
					float4 TtoW1:TEXCOORD3;
					float4 TtoW2:TEXCOORD4;
				};

				v2f vert(a2v v){
					v2f o;
					o.pos=UnityObjectToClipPos(v.vertex);
					o.scrPos=ComputeGrabScreenPos(o.pos);
					o.uv.xy=TRANSFORM_TEX(v.vertex,_MainTex);
					o.uv.zw=TRANSFORM_TEX(v.vertex,_BumpTex);

					float3 worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;

					fixed3 worldNormal=UnityObjectToWorldNormal(v.normal);
					fixed3 worldTangent=UnityObjectToWorldDir(v.tangent.xyz);
					fixed3 worldBinormal=cross(worldNormal,worldTangent)*v.tangent.w;

					o.TtoW0=(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
					o.TtoW1=(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
					o.TtoW2=(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

					return o;
				}

				fixed4 frag(v2f i):SV_Target{
					float3 worldPos=(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
					fixed3 worldViewDir=normalize(UnityWorldSpaceViewDir(worldPos));

					fixed3 bump=UnpackNormal(tex2D(_BumpTex,i.uv.zw));

					float2 offset=bump*_Distortion*_RefractionTex_TexelSize.xy;
					i.scrPos.xy=offset+i.scrPos.xy;
					fixed3 refrColor=tex2D(_RefractionTex,i.scrPos.xy/i.scrPos.w).rgb;

					bump=normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));
					fixed3 reflectDir=reflect(-worldViewDir,bump);
					fixed4 texColor=tex2D(_MainTex,i.uv.xy);
					fixed3 reflColor=texCUBE(_CubeMap,reflectDir).rgb*texColor.rgb;

					fixed3 finalColor=reflColor*(1-_RefractAmount)+refrColor*_RefractAmount;

					return fixed4(finalColor,1.0);

				}
			ENDCG
		}
	}
	FallBack "Tranparent/VertexLit"
}
