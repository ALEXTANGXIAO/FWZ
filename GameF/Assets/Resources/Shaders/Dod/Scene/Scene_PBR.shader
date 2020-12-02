Shader "Dodjoy/Scene/Scene_PBR" {
	Properties {
		_MainColor ("Main Color", Color) = (1,1,1,1)
		_Saturation("Saturation", float) = 1//���Ͷ�����
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_EmissionColor ("Emission Color", Color) = (1,1,1,1)
		_EmissionRange("EmissionRange", range(0, 2)) = 1
		_BumpTex("Normal", 2D) = "bump" {}
		_MetallicTex("Metallic", 2D) = "white" {}
		_Smoothness("Smoothness", range(0, 1)) = 1
		_MetallicScale("MetallicScale", Range(0, 1)) = 1
		
	}

	SubShader {
		Tags { "RenderType"="Opaque" }

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert finalcolor:FinalColor
		#pragma multi_compile DOD_FOG_LINEAR
		#include "CustomFog.cginc"

		sampler2D _MainTex;
		sampler2D _BumpTex;
		sampler2D _MetallicTex;
		half _Smoothness;
		half _EmissionRange;
		fixed4 _MainColor;
		fixed4 _EmissionColor;
		half _Saturation;//���Ͷ�����

		float _MetallicScale;
		

		struct Input {
			float2 uv_MainTex;
			CUSTOM_FOG_COORDS(1)
			float3 worldPos;
		};

		void vert(inout appdata_full v, out Input data)
		{
			UNITY_INITIALIZE_OUTPUT(Input, data);
			data.worldPos = mul(unity_ObjectToWorld, v.vertex);
			CUSTOM_TRANSFER_FOG(data.fogCoord, v.vertex);
		}

		void FinalColor(Input IN, SurfaceOutputStandard o, inout fixed4 color)
		{
			CUSTOM_APPLY_FOG(IN.fogCoord, IN.worldPos, color.rgb);
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _MainColor;
			o.Albedo = c.rgb;
			o.Alpha = c.a;

			fixed lum = 0.2125 * o.Albedo.r + 0.7154 * o.Albedo.g + 0.0721 * o.Albedo.b;
			fixed4 lumColor = fixed4(lum, lum, lum, c.a);
			o.Albedo = lerp(lumColor, o.Albedo.rgb, _Saturation);
			//���Ͷ�����

			fixed3 normal = UnpackNormal(tex2D(_BumpTex, IN.uv_MainTex));
			o.Normal = normal;

			fixed4 metallicMask = tex2D(_MetallicTex, IN.uv_MainTex);
			o.Metallic = metallicMask.r * _MetallicScale;
			o.Emission =  c.rgb * metallicMask.g * _EmissionRange * _EmissionColor;
			//Bͨ������		
			o.Smoothness = metallicMask.a * _Smoothness;
			
		}
		ENDCG
	}

	Fallback "Mobile/VertexLit"
}


