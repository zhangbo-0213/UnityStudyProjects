Shader "Custom/Scan" {
	Properties{
		_MainColor("MainColor",Color)=(1,1,1,1)
		_HighLightingColor("HighLightingColor",Color)=(1,1,1,1)
		_Threshold("Threshold",Float)=2.0
		_MainTex("MainTex",2D)="white"{}
	}
	SubShader{
		Tags{"Queue"="Transparent" "RenderType"="Transparent"}
		//设置合理的渲染队列，使当前扫描平面在其他物体后渲染
		Pass{
			Tags{"LightMode"="ForwardBase"}

			Blend SrcAlpha OneMinusSrcAlpha
			//设置混合，使得扫描平面后面的部分仍然被看见
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include "UnityCG.cginc"

			//提前定义
			uniform sampler2D_float _CameraDepthTexture;

			 fixed4 _MainColor;
			 fixed4 _HighLightingColor;
			 float   _Threshold;
			 sampler2D  _MainTex;
			 float4         _MainTex_ST;

			 struct a2v{
				float4 vertex:POSITION;
				float4 texcoord:TEXCOORD0;
			 };

			 struct v2f{
				float4 pos:SV_POSITION;
				float4 projPos:TEXCOORD0;
				float3 viewPos:TEXCOORD1;
				float2 uv:TEXCOORD2; 
			};

			v2f vert(a2v v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);
				o.projPos=ComputeScreenPos(o.pos);
				o.viewPos=UnityObjectToViewPos(v.vertex);
				o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
				return o;
			}

			fixed4 frag(v2f i):SV_Target{
				fixed4 finalColor=_MainColor;
				float sceneZ=LinearEyeDepth(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD(i.projPos)));
				//使用LinearEyeDepth得到在观察空间下的深度值，这里需要注意的是Unity的观察空间中，摄像机正向对应着的z值
				//为负值，而为了得到深度值的正数表示，将原观察空间的深度值这里做了一个取反的操作
				float partZ=-i.viewPos.z;
				//因此这里得到当前平面的观察空间深度值后，取了反，与上面得到的结果对应
				float diff=min((abs(sceneZ-partZ))/_Threshold,1.0);
				//这里通过两者深度值的插值/阈值控制颜色插值运算的结果，深度值相差太大则是扫描平面自身颜色
				//而差值越小，则越接近高亮颜色
				finalColor=lerp(_HighLightingColor,_MainColor,diff)*tex2D(_MainTex,i.uv);

				return finalColor;
			}
			ENDCG
		}
	}
	FallBack "Transparent/VertexLit"
}
