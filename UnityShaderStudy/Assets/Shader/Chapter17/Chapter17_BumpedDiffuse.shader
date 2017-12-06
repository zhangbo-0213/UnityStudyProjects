Shader "Custom/Chapter17_BumpedDiffuse" {
	Properties{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex("MainTex",2D)="white"{}
		_BumpMap("NormalMap",2D)="bump"{}
		_Specular("SpecularColor",Float)=1.0
		_Gloss("Gloss",Range(8.0,255))=20
	}
	SubShader{
		Tags{"Renderer"="Opaque"}
		LOD 300

		CGPROGRAM
		#pragma surface surf BlinnPhong
		#pragma target 3.0

		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		float _Specular;
		float _Gloss;

		struct Input{
			float2 uv_MainTex;
			float2 uv_BumpMap;
		};

		void surf (Input IN,inout SurfaceOutput o){
			fixed4 tex=tex2D(_MainTex,IN.uv_MainTex);
			o.Albedo=tex.rgb*_Color.rgb;
			o.Alpha=tex.a*_Color.a;
			o.Normal=UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.Specular=_Specular;
			o.Gloss=_Gloss;
		}
		ENDCG
	}
	FallBack "Legacy Shader/Diffuse"
}
