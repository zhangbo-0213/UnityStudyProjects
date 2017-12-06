Shader "Custom/Chapter17_NormalExtrusion" {
	Properties{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex("MainTex",2D)="white"{}
		_BumpMap("BumpMap",2D)="bump"{}
		_Amount("ExtrusionAmount",Range(-0.5,0.5))=0.1
	}
	SubShader{
		Tags{"RenderType"="Opaque"}
		LOD 300

		CGPROGRAM
		#pragma surface surf CustomLambert vertex:myvert finalcolor:mycolor addshadow exclude_path:deferred exclude_path:prepass nometa
		#pragma target 3.0

		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		half _Amount;

		struct Input{
			float2 uv_MainTex;
			float2 uv_BumpMap;
		};

		//自定义顶点修改函数
		void myvert(inout appdata_full v){
			v.vertex.xyz+=v.normal*_Amount;
		}

		//自定义表面函数
		void surf(Input IN,inout SurfaceOutput o){
			fixed4 tex=tex2D(_MainTex,IN.uv_MainTex);
			o.Albedo=tex.rgb;
			o.Normal=UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.Alpha=tex.a;	
		}

		//自定义的光照模型函数，兰伯特光照模型，返回漫反射颜色值
		half4 LightingCustomLambert(SurfaceOutput s,half3 lightDir,half atten){
			half NdotL=dot(s.Normal,lightDir);
			half4 c;
			c.rgb=s.Albedo*_LightColor0.rgb*(NdotL*atten);
			c.a=s.Alpha;
			return c;
		}

		//自定义最后颜色修改函数，将光照模型函数的输出作为输入，与_Color的值进行叠加
		void mycolor(Input IN,SurfaceOutput o,inout fixed4 color){
			color*=_Color;
		}
		ENDCG
	}
	FallBack "Legacy Shaders/Diffuse"
}
