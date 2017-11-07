Shader "Custom/Chapter13_MotionBlurWithDepthTexture" {
	Properties{
		_MainTex("Maintex",2D)="white"{}
		_BlurSize("BlurSize",Float)=1.0
	}
	SubShader{
		CGINCLUDE
			
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			sampler2D _CameraDepthTexture;
			float4x4 _PreviousViewProjectionMatrix;
			float4x4 _CurrentViewProjectionInverseMatrix;
			half _BlurSize;

			struct v2f{
				float4 pos:POSITION;
				half2 uv:TEXCOORD0;
				half2 uv_depth:TEXCOORD1;
			};


			v2f vert(appdata_img v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);
				o.uv=v.texcoord;
				o.uv_depth=v.texcoord;
				#if UNITY_UV_STARTS_AT_TOP
				if(_MainTex_TexelSize.y<0)
					o.uv_depth.y=1-o.uv_depth.y;
				#endif

				return o;
			}

			fixed4 frag(v2f i):SV_Target{
				//得到深度缓冲中该像素点的深度值
				float d=SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth);
				//得到深度纹理映射前的深度值
				float4 H=float4(i.uv.x*2-1,i.uv.y*2-1,d*2-1,1);
				//通过转换矩阵得到顶点的世界空间的坐标值
				float4 D=mul(_CurrentViewProjectionInverseMatrix,H);
				float4 worldPos=D/D.w;

				float4 currentPos=H;
				float4 previousPos=mul(_PreviousViewProjectionMatrix,worldPos);
				previousPos/=previousPos.w;

				float2 velocity=(currentPos.xy-previousPos.xy)/2.0f;

				float2 uv=i.uv;
				float4 c=tex2D(_MainTex,uv);
				//得到像素速度后，对邻域像素进行采样，并使用BlurSize控制采样间隔
				//得到的像素点进行平均后，得到模糊效果
				uv+=velocity*_BlurSize;
				for(int it=1;it<3;it++,uv+=velocity*_BlurSize){
					float4 currentColor=tex2D(_MainTex,uv);
					c+=currentColor;
				}
				c/=3;
				return fixed4(c.rgb,1.0);
			}
		ENDCG

		Pass{
			ZTest Always 
			Cull Off
			ZWrite Off

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
			ENDCG
		}
	}

	FallBack Off
}
