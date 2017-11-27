Shader "Custom/Chapter15_WaterWave" {
	Properties{
		_Color("MainColor",Color)=(1,1,1,1)   //水面颜色
		_MainTex("MainTex",2D)="white"{}    //水面纹理
		_WaveMap("WaveMap",2D)="bump"{}
		_CubeMap("CubeMap",Cube)="_Skybox"{}
		_WaveXSpeed("WaveXSpeed",Range(-0.1,0.1))=0.01
		_WaveYSpeed("WaveYSpeed",Range(-0.1,0.1))=0.01
		_Distortion("Distortion",Range(0,100))=10   //控制图像扭曲程度
	}

	SubShader{
		Tags{"Queue"="Transparent" "RenderType"="Opaque"}
		//这里设置渲染队列为Transparent,是为了保证渲染该物体前，其他所有不透明物体已经被渲染
		//而设置渲染类型则是为了使用摄像机的深度和法线纹理时，物体被正确渲染（会使用着色器替换技术）
		GrabPass{"_RefractionTex"}
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _WaveMap;
			float4 _WaveMap_ST;
			samplerCUBE _CubeMap;
			fixed _WaveXSpeed;
			fixed _WaveYSpeed;
			float _Distortion;
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;

			struct a2v{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
				float4 texcoord:TEXCOORD0;
			};

			struct v2f{
				float4 pos:SV_POSITION;
				float4 srcPos:TEXCOORD0;
				float4 uv:TEXCOORD1;
				float4 TtoW0:TEXCOORD2;
				float4 TtoW1:TEXCOORD3;
				float4 TtoW2:TEXCOORD4;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);    
				o.srcPos=ComputeGrabScreenPos(o.pos);
				o.uv.xy=TRANSFORM_TEX(v.texcoord,_MainTex);
				o.uv.zw=TRANSFORM_TEX(v.texcoord,_WaveMap);

				float3 worldPos=mul(unity_ObjectToWorld,v.vertex);
				float3 worldNormal=UnityObjectToWorldNormal(v.normal);
				float3 worldTangent=UnityObjectToWorldDir(v.tangent.xyz);
				float3 worldBinormal=cross(worldNormal,worldTangent)*v.tangent.w;

				o.TtoW0=float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
				o.TtoW1=float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
				o.TtoW2=float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

				return o;
			}

			fixed4 frag(v2f i):SV_Target{
				float3 worldPos=float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				fixed3 viewDir=normalize(UnityWorldSpaceViewDir(worldPos));
				float2 speed=_Time.y*float2(_WaveXSpeed,_WaveYSpeed); //_Time(t/20,t,2t,3t)

				//切线空间下的法线采样并反解
				fixed3 bump1=UnpackNormal(tex2D(_WaveMap,i.uv.zw+speed)).rgb;
				fixed3 bump2=UnpackNormal(tex2D(_WaveMap,i.uv.zw-speed)).rgb;
				fixed3 bump=normalize(bump1+bump2);
				//两次对法线纹理采样，模拟两层水面交叉效果

				//使用切线空间下的法线进行偏移，该空间下的法线可以反映顶点局部空间下的法线方向
				float2 offset=bump.xy*_Distortion*_RefractionTex_TexelSize;
				i.srcPos.xy=offset*i.srcPos.z+i.srcPos.xy; //使用i.srcPos.z与偏移相乘，模拟深度越大，折射越强的效果
				fixed3 refrCol=tex2D(_RefractionTex,i.srcPos.xy/i.srcPos.w).rgb;

				//进行矩阵变换，得到世界空间下的法线方向
				bump=normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));
				fixed3 texColor=tex2D(_MainTex,i.uv.xy+speed);
				fixed3 reflDir=reflect(-viewDir,bump);
				fixed3 reflCol=texCUBE(_CubeMap,reflDir).rgb*texColor*_Color;

				fixed3 fresnel=pow(1-max(0,dot(viewDir,bump)),4);
				fixed3 finalColor=refrCol*(1-fresnel)+reflCol*fresnel;

				return fixed4(finalColor,1);
			}
			ENDCG
		}
	}
	FallBack "Transparent"
}
