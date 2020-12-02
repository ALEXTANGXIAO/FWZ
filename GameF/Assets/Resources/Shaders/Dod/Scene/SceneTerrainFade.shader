

Shader "Dodjoy/Scene/SceneTerrainFade"
{
    Properties
    {
		_MainColor ("Main Color(RGB)", Color) = (1,1,1,1)
		_Splat0 ("Layer 1", 2D) = "white" {}
		_Splat1 ("Layer 2", 2D) = "white" {}
		_Splat2 ("Layer 3", 2D) = "white" {}
		_Splat3 ("Layer 4", 2D) = "white" {}
		_Control ("Control (RGBA)", 2D) = "white" {}
        _MainTex ("Texture", 2D) = "white" {}
		[Toggle(DOD_SUN_ON)]_SunOn("Sun on", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
		
		Cull Back
		LOD 600
        Pass
        {
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex SceneVert
            #pragma fragment SceneFrag   

			#define FADE_ON
			#define MIDLIGHT_ON
			#define SHADOW_ON
			#define DOD_SUN_ON
			#define LINEARCOLOR
			#define TERRAIN
			#define HIGHTFOG
			#define DOD_FOG_LINEAR
			#pragma multi_compile_fwdbase
			#pragma multi_compile DOD_PLATFORM_MOBILE 
			#pragma multi_compile_instancing
			#include "DodScenePbsCore.cginc"

            ENDCG
        }
    }


	SubShader
    {
        Tags { "RenderType"="Opaque" }
		
		Cull Back
		LOD 300
        Pass
        {
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex SceneVert
            #pragma fragment SceneFrag   
			#define MIDLIGHT_ON
			#define SHADOW_ON
			#define FADE_ON
			#define DOD_FOG_LINEAR
			#define TERRAIN
			#pragma multi_compile_fwdbase
			#pragma multi_compile DOD_PLATFORM_MOBILE 
			#pragma multi_compile_instancing
			#include "DodScenePbsCore.cginc"

            ENDCG
        }
    }
		SubShader
    {
        Tags { "RenderType"="Opaque" }
		
		Cull Back
		LOD 200
        Pass
        {
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex SceneVert
            #pragma fragment SceneFrag   
			#define SIMPLELIGHT_ON
			#define DOD_FOG_LINEAR
			#define TERRAIN
			#define FADE_ON
			#pragma multi_compile_fwdbase
			#pragma multi_compile DOD_PLATFORM_MOBILE 
			#pragma multi_compile_instancing
			#include "DodScenePbsCore.cginc"

            ENDCG
        }
    }
	Fallback "Diffuse"
}
