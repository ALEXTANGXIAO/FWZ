﻿// customLightmap
// by baogang 

Shader "Dodjoy/Scene/SceneDiff"
{
    Properties
    {
		_MainColor("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
		_EmissionColor("EmissionColor", Color) = (1, 1, 1, 1)
		_Emission("Emission",range(1,18)) = 1.0
		_MaskTex ("Mask Texture", 2D) = "black" {}
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

			#define MIDLIGHT_ON
			#define SHADOW_ON
			#define DOD_SUN_ON
			#define HIGHTFOG
			#define LINEARCOLOR
			#define DOD_FOG_LINEAR
			#define DOD_PLATFORM_MOBILE
			#pragma multi_compile LIGHTMAP_ON
			#pragma multi_compile_fwdbase
//			#pragma multi_compile SHADOWS_SHADOWMASK;
//			#pragma multi_compile DOD_PLATFORM_MOBILE
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
			#define DOD_FOG_LINEAR
			#define DOD_PLATFORM_MOBILE
			#pragma multi_compile LIGHTMAP_ON
			#pragma multi_compile_fwdbase
//			#pragma multi_compile SHADOWS_SHADOWMASK;
			//#pragma multi_compile DOD_FOG_NONE DOD_FOG_LINEAR DOD_FOG_EXP DOD_FOG_EXP2
//			#pragma multi_compile DOD_PLATFORM_MOBILE
//			#pragma shader_feature DOD_SUN_ON  
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
			#define DOD_PLATFORM_MOBILE
			#pragma multi_compile LIGHTMAP_ON

			#pragma multi_compile_fwdbase
//			#pragma multi_compile DOD_PLATFORM_MOBILE
			#pragma multi_compile_instancing
			#include "DodScenePbsCore.cginc"

            ENDCG
        }
    }

	Fallback "Dodjoy/FallBack"
}
