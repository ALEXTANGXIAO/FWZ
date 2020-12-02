
Shader "Dodjoy/Scene/SceneItemAlphaTest"    
{
	Properties 
	{
		_MainColor ("Main Color(RGB)", Color) = (1,1,1,1)
		_MainTex   ("Texture(RGBA)", 2D)      = "white" {}
		_Cutoff    ("Alpha cutoff", Range(0,1)) = 0.5
	}

	SubShader 
	{
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}

		Cull Off 
		LOD 600
		Pass 
		{
			
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex SceneVert
            #pragma fragment SceneFrag   

			#define MIDLIGHT_ON
			#define SHADOW_ON
			#define DOD_SUN_ON
			#define DOD_FOG_LINEAR
			#define HIGHTFOG
			#define LINEARCOLOR
			#define CUTOFF
			#define DOD_PLATFORM_MOBILE
			#pragma multi_compile_fwdbase
			#pragma multi_compile_instancing
			#include "DodScenePbsCore.cginc"

            ENDCG
		}
	}
	SubShader 
	{
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}

		Cull Off 
		LOD 300
		Pass 
		{
			
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex SceneVert
            #pragma fragment SceneFrag   

			#define MIDLIGHT_ON
			#define SHADOW_ON
			#define DOD_FOG_LINEAR
			#define CUTOFF
			#define DOD_PLATFORM_MOBILE
			#pragma multi_compile_fwdbase

			#pragma multi_compile_instancing
			#include "DodScenePbsCore.cginc"

            ENDCG
		}
	}

	SubShader 
	{
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}

		Cull Off 
		LOD 200
		Pass 
		{
			
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex SceneVert
            #pragma fragment SceneFrag   

			#define SIMPLELIGHT_ON
			#define DOD_FOG_LINEAR
			#define CUTOFF
			#define DOD_PLATFORM_MOBILE
			#pragma multi_compile_fwdbase
			#pragma multi_compile_instancing
			#include "DodScenePbsCore.cginc"

            ENDCG
		}
	}
	
	Fallback "Dodjoy/FallBack"
}
