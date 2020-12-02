Shader "Dodjoy/PostProcess/Fog"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		ZTest Always Cull Off ZWrite Off
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			sampler2D _NoiseTex;
			sampler2D _CameraDepthTexture;
			fixed4 _FogColor;
			half _FogDensity;
			float _FogStart;
			float _FogEnd;
			float _FogStartHeight;
			float _FogEndHeight;

			half _FogDensityXY;
			half _FogDensityZW;

			float _FogXSpeed;
			float _FogYSpeed;
			//获得相机近裁面四个角向量
			float4x4 _FrustumCornersRay;

			fixed4 _Color;

			struct v2f{
				float4 pos:SV_POSITION;
				float2 uv:TEXCOORD0;
				float2 uv_depth:TEXCOORD1;
				float4 interpolatedRay:TEXCOORD2;
			};

			v2f vert(appdata_img v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);
				o.uv=v.texcoord;
				o.uv_depth = v.texcoord;

#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					o.uv_depth.y = 1 - o.uv_depth.y;
#endif
				int index=0;
				if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5)
				{
					index = 0;
				}
				else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
					index = 1;
				}
				else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
					index = 2;
				}
				else {
					index = 3;
				}
#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					index = 3 - index;
#endif

				//安排uv4个角对应四个角向量
				o.interpolatedRay = _FrustumCornersRay[index];
				return o;
			}

			float4 frag(v2f i):SV_Target{
				//观察空间下的线性深度值
				float linearDepth=LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth));
				//像素世界坐标=世界空间相机位置+像素相对相机距离
				float3 worldPos = _WorldSpaceCameraPos+linearDepth*i.interpolatedRay.xyz;
				float speedX = _Time.y*_FogXSpeed;
				float speedY = _Time.y*_FogYSpeed;
				float noise = tex2D(_NoiseTex,i.uv + float2(speedX,speedY));
				//让噪声图向黑色靠拢，黑白差距不要太大
				noise = pow(noise,0.5);
				//雾浓度=世界高度/指定范围
				float fogDensity1 = (_FogEndHeight - worldPos.y)/(_FogEndHeight - _FogStartHeight) * _FogDensityZW;
				float fogDensity2 = (1 - (_FogEnd - abs(worldPos.z - _WorldSpaceCameraPos.z)) / (_FogEnd - _FogStart)) * _FogDensityXY;
				fogDensity2 = pow(fogDensity2, 0.5);
				//混合深度和高度
				float fogDensity = smoothstep(0.0, 1.0, fogDensity1 * fogDensity2) * _FogDensity;
				fogDensity = pow(fogDensity, 0.5);

				fogDensity = smoothstep(0.0, 1.0, fogDensity * noise);
				float4 color = tex2D(_MainTex, i.uv);
				//根据雾浓度混合场景和雾颜色
				color.rgb = lerp(color.rgb, _FogColor, fogDensity);
				color.a = _FogColor.a;
				return color;
			}

			ENDCG
		}//endpass	
	}
	Fallback Off
}
