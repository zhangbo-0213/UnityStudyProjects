// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Chapter5_SimpleShader" {

	Properties{
		_Color("Color Tint",Color) = (1.0,1.0,1.0,1.0)
	}
		SubShader{
			Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag  

		//在CG代码中，需要定义一个与属性名称和类型匹配的变量
			fixed4 _Color;

		//通过一个结构体定义顶点着色器的输入
		struct a2v {
		    //使用POSITION语义，将模型空间的顶点坐标填充至vertex
			float4 vertex:POSITION;
			//使用NORMAL语义，将模型空间的顶点法线填充至normal（由于是矢量，这里使用float3）
			float3 normal:NORMAL;
			//使用TEXCOORD0语义，将模型的第一套纹理坐标填充texcoord变量
			float4 texcoord:TEXCOORD0;
		};
		
		//使用一个结构体定义片元着色器的输出
		struct v2f {
			//SV_POSITION语义告诉Unity，pos中包含模型顶点在裁剪空间的坐标
			float4 pos:SV_POSITION;
			//COLOR0语义告诉Unity,color用于存储颜色信息
			fixed3 color : COLOR0;
		};

	      v2f vert(a2v v) {
			//声明输出结构
			v2f o;
			o.pos= UnityObjectToClipPos(v.vertex);
			//将法线方向映射到颜色中(法线矢量范围[-1,1],因此做一个映射计算)  
			o.color = v.normal*0.5 + fixed3(0.5,0.5,0.5);
			return o;
		}

		fixed4 frag(v2f i) : SV_Target{
			//将计算后的颜色显示出来
			fixed3 c= i.color;
			//使用_Color属性控制颜色属性
			c *= _Color.rgb;
			return fixed4(c,1.0);
		}

		ENDCG
	}
	}
	FallBack "Diffuse"
}
