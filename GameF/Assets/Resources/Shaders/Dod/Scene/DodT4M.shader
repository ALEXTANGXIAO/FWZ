Shader "Dodjoy/Scene/T4M 4 TexturesBumpSpec" {
	Properties{
		_Splat0("Layer 1", 2D) = "white" {}
		_Splat1("Layer 2", 2D) = "white" {}
		_Splat2("Layer 3", 2D) = "white" {}
		_Splat3("Layer 4", 2D) = "white" {}
		_Control("Control (RGBA)", 2D) = "white" {}
		_MainTex("Never Used", 2D) = "white" {}

		[KeywordEnum(None, Layer1, Layer2, Layer3, Layer4)] _Overlay("Layer Index", Float) = 0
		_BumpTex("Normal", 2D) = "bump"{}

		_SpecColor("Spec Color", Color) = (0.5, 0.5, 0.5, 1)
		_SpecScale("Specular Scale", Range(0.1, 10)) = 1
		_Shininess("Shininess", Range(1, 256)) = 8
	}

		SubShader{
			Tags {
		   "SplatCount" = "4"
		   "RenderType" = "Opaque"
			}
		CGPROGRAM
		#pragma surface surf BlinnPhong vertex:vert finalcolor:FinalColor
		#pragma exclude_renderers xbox360 ps3
		#pragma shader_feature _OVERLAY_NONE _OVERLAY_LAYER1 _OVERLAY_LAYER2 _OVERLAY_LAYER3 _OVERLAY_LAYER4
		#pragma multi_compile DOD_FOG_NONE DOD_FOG_LINEAR DOD_FOG_EXP DOD_FOG_EXP2
		
		#pragma target 3.0

		#include "CustomFog.cginc"
		sampler2D _Control;
		float4 _Control_ST;
		sampler2D _Splat0,_Splat1,_Splat2,_Splat3;
		float4 _Splat0_ST,_Splat1_ST,_Splat2_ST,_Splat3_ST;
		sampler2D _BumpTex;
		float2 uvNormal;
		float _SpecScale;
		fixed4 _SpecularColor;
		float _Shininess;

		
		struct Input {
			float2 tc_Control : TEXCOORD0;
			float2 tc_Splat0 : TEXCOORD1;
			float2 tc_Splat1 : TEXCOORD2;
			float2 tc_Splat2 : TEXCOORD3;
			float2 tc_Splat3 : TEXCOORD4;
			CUSTOM_FOG_COORDS(5)
			float3 worldPos : TEXCOORD6;
		};

		void vert(inout appdata_full v, out Input data)
		{
			UNITY_INITIALIZE_OUTPUT(Input, data);
			data.tc_Control.xy = TRANSFORM_TEX(v.texcoord, _Control);
			data.tc_Splat0 = TRANSFORM_TEX(v.texcoord, _Splat0);
			data.tc_Splat1 = TRANSFORM_TEX(v.texcoord, _Splat1);
			data.tc_Splat2 = TRANSFORM_TEX(v.texcoord, _Splat2);
			data.tc_Splat3 = TRANSFORM_TEX(v.texcoord, _Splat3);
			data.worldPos = mul(unity_ObjectToWorld, v.vertex);
			CUSTOM_TRANSFER_FOG(data.fogCoord, v.vertex);
		}

		void FinalColor(Input IN, SurfaceOutput o, inout fixed4 color)
		{
			CUSTOM_APPLY_FOG(IN.fogCoord, IN.worldPos, color.rgb);
		}

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 splat_control = tex2D(_Control, IN.tc_Control).rgba;

			fixed4 lay1 = tex2D(_Splat0, IN.tc_Splat0);
			fixed4 lay2 = tex2D(_Splat1, IN.tc_Splat1);
			fixed4 lay3 = tex2D(_Splat2, IN.tc_Splat2);
			fixed4 lay4 = tex2D(_Splat3, IN.tc_Splat3);

			o.Alpha = 0.0;
			o.Albedo.rgb = (lay1 * splat_control.r + lay2 * splat_control.g + lay3 * splat_control.b + lay4 * splat_control.a);
		
			float2 uvNormal = 0;
			float mask = 0;
			float gloss = 0;
#if _OVERLAY_LAYER1
			uvNormal = IN.tc_Splat0;
			mask = splat_control.r;
			gloss = lay1.a;
#elif _OVERLAY_LAYER2
			uvNormal = IN.tc_Splat1;
			mask = splat_control.g;
			gloss = lay2.a;
#elif _OVERLAY_LAYER3
			uvNormal = IN.tc_Splat2;
			mask = splat_control.b;
			gloss = lay3.a;
#elif _OVERLAY_LAYER4
			uvNormal = IN.tc_Splat3;
			mask = splat_control.a;
			gloss = lay4.a;
#endif
			fixed3 normal = UnpackNormal(tex2D(_BumpTex, uvNormal));
			o.Normal = normal * mask + (1 - mask) * fixed3(0, 0, 1);

			o.Specular = _Shininess;
			o.Gloss = _SpecScale * mask * gloss;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
