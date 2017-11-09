Shader "Custom/Chapter13_EdgeDetectWithNormalsAndDepth" {
	Properties{
		_MainTex("MainTex",2D)="white"{}
		_EdgeOnly("EdgeOnly",Float)=1.0
		_EdgeColor("EdgeColor",Color)=(0,0,0,1)
		_BackgroundColor("BackgroundColor",Color)=(1,1,1,1)
		_SampleDistance("SampleDistance",Float)=1.0
		_Sensitivity("Sensitivity",Vector)=(1,1,1,1)
	}
	SubShader{
		CGINCLUDE
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		fixed _EdgeOnly;
		fixed4 _EdgeColor;
		fixed4 _BackgroundColor;
		float _SampleDistance;
		half4 _Sensitivity;
		sampler2D _CameraDepthNormalsTexture;
		
		struct v2f{
			float4 pos:SV_POSITION;
			half2 uv[5]:TEXCOORD0;
		};		

		v2f vert(appdata_img v){
			v2f o;
			o.pos=UnityObjectToClipPos(v.vertex);
			half2 uv=v.texcoord;
			o.uv[0]=uv;

			#if UNITY_UV_STARTS_AT_TOP	
			if(_MainTex_TexelSize.y<0)
			uv.y=1-uv.y;
			#endif

			o.uv[1]=uv+_MainTex_TexelSize.xy*half2(1,1)*_SampleDistance;
			o.uv[2]=uv+_MainTex_TexelSize.xy*half2(-1,-1)*_SampleDistance;
			o.uv[3]=uv+_MainTex_TexelSize.xy*half2(-1,1)*_SampleDistance;
			o.uv[4]=uv+_MainTex_TexelSize.xy*half2(1,-1)*_SampleDistance;

			return o;
		}

		//检测给定的采样点之间是否存在一条分界线
		half CheckSame(half4 center,half4 sample){
			half2 centerNormal=center.xy;
			float centerDepth=DecodeFloatRG(center.zw);
			half2 sampleNormal=sample.xy;
			float sampleDepth=DecodeFloatRG(sample.zw);

			//检测两者法线值的差异，如果两者法线值足够接近，那么说明不存在分界线
			//法线值并没有进行解码，因为只需要知道两者的差异，不需要准确的解码值
			half2 diffNormal=abs(centerNormal-sampleNormal)*_Sensitivity.x;
			int isSameNormal=(diffNormal.x+diffNormal.y)<0.1;  

			//检测两者深度值值的差异，如果两者深度值足够接近，那么说明不存在分界线
			float diffDepth=abs(centerDepth-sampleDepth)*_Sensitivity.y;
			int isSameDepth=diffDepth<0.1*centerDepth;

			//只有两者的法线和深度值差异均在阈值范围内，才可以看做是不存在分界线
			return isSameNormal*isSameDepth?1.0:0.0;
		}

		fixed4 fragRobertsCrossDepthAndNormal(v2f i):SV_Target{
			//根据Roberts算子对深度法线图对应像素的周围像素采样
			half4 sample1=tex2D(_CameraDepthNormalsTexture,i.uv[1]);
			half4 sample2=tex2D(_CameraDepthNormalsTexture,i.uv[2]);
			half4 sample3=tex2D(_CameraDepthNormalsTexture,i.uv[3]);
			half4 sample4=tex2D(_CameraDepthNormalsTexture,i.uv[4]);

			half edge=1.0;
			edge*=CheckSame(sample1,sample2);
			edge*=CheckSame(sample3,sample4);

			//通过计算得到edge，设置非边界像素的颜色为原色还是背景色的着色方案
			fixed4 withEdgeColor=lerp(_EdgeColor,tex2D(_MainTex,i.uv[0]),edge);
			fixed4 withBackgroundColor=lerp(_EdgeColor,_BackgroundColor,edge);
			//使用_EdgeOnly控制非边界像素的颜色混合结果
			return lerp(withBackgroundColor,withEdgeColor,_EdgeOnly);
		}
		ENDCG
		Pass{
		ZTest Always ZWrite Off Cull Off

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment fragRobertsCrossDepthAndNormal
		ENDCG
		}
	}
	FallBack Off
}
