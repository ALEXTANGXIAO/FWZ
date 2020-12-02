Shader "Dodjoy/Actor/ActorEye" 
{
	Properties 
	{
		_MainColor("Eye Color (A-Color blend)", Color) = (0,0,0,1)
		_MainTex ("Base (RGB)", 2D) = "grey" {}
		_MaskTex ("Mask(R-Specular, G-EyeColor, B-Reflect, A-Shadow)", 2D) = "white" {}
		_ReflectMatcap("Reflect Matcap", 2D) = "black"{}

		_DiffScale("Diffuse Scale", Range(0, 5)) = 1
		_DiffWrap("Diffuse Wrap", Range(0, 2)) = 1
		_SpecScale("Specular Scale", Range(0, 10)) = 1
		_SpecOffsetX("Specluar offsetX", Range(-2, 2)) = 0
		_SpecOffsetY("Specluar offsetY", Range(-2, 2)) = 0
		_ReflScale ("Reflect Scale", Range(0, 10)) = 1
		_ShadowScale("Shadow Scale", Range(0, 1)) = 1

	}

	SubShader 
	{ 
		Tags { "Queue"="Geometry" "RenderType"="Opaque"}
		LOD 600
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#define CUSTOM_MAIN_LIGHT
			#define CUSTOM_ENV_LIGHT_ON
			#define LIGHT_ON
			#define REFLECT_ON	

			#include "DodEyeCore.cginc"		
			ENDCG
		}
		UsePass "Dodjoy/Actor/ActorShdow/SHADOW"
	}

	SubShader
	{
		Tags{"Queue"="Geometry" "RenderType"="Opaque"}
		LOD 300
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#define CUSTOM_MAIN_LIGHT
			#define CUSTOM_ENV_LIGHT_ON
			#define LIGHT_ON

			#include "DodEyeCore.cginc"
			ENDCG
		}
		UsePass "Dodjoy/Actor/ActorShdow/SHADOW"
	}

	SubShader
	{
		Tags{"Queue"="Geometry" "IgnorProjector"="True" "RenderType"="Opaque" "ForceNoShadowCasting"="true"}
		LOD 200
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define CUSTOM_MAIN_LIGHT
			#define CUSTOM_ENV_LIGHT_ON
			#include "DodEyeCore.cginc"
			ENDCG
		}
	}

	FallBack "Dodjoy/FallBack"
}

