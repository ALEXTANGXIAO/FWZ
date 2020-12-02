Shader "Dodjoy/Scene/SceneItemTransparent"         //新增半透明材质  //JianpingWang //20200519
{
    Properties
    {
        _MainColor("Color(RGBA)", Color) = (1,1,1,1)
        [NoScaleOffset]
        _MainTex ("Texture(RGBA)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue"="Transparent" }
		
		LOD 600
		Pass {
			ZWrite Off
			ColorMask 0
        }
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            Blend SrcAlpha OneMinusSrcAlpha
    		ZWrite Off
            CGPROGRAM
            #pragma vertex SceneVert
            #pragma fragment SceneFrag   

			#define MIDLIGHT_ON
			#define SHADOW_ON
			#define DOD_SUN_ON
			#define DOD_FOG_LINEAR
			#define HIGHTFOG
			#define LINEARCOLOR
			#define TRANSPARENT
			#define DOD_PLATFORM_MOBILE
			#pragma multi_compile_fwdbase

//			#pragma multi_compile DOD_PLATFORM_PC DOD_PLATFORM_MOBILE
			#pragma multi_compile_instancing
			#include "DodScenePbsCore.cginc"

            ENDCG
        }
    }

	SubShader
    {
        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue"="Transparent" }        
        Blend SrcAlpha OneMinusSrcAlpha
    	ZWrite Off 
		LOD 300
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
           
            CGPROGRAM
            #pragma vertex SceneVert
            #pragma fragment SceneFrag   

			#define MIDLIGHT_ON
			#define DOD_FOG_LINEAR
			#define TRANSPARENT
			#define DOD_PLATFORM_MOBILE
			#pragma multi_compile_fwdbase

//			#pragma multi_compile DOD_PLATFORM_PC DOD_PLATFORM_MOBILE
			#pragma multi_compile_instancing
			#include "DodScenePbsCore.cginc"

            ENDCG
        }
	}
    SubShader
    {
        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue"="Transparent" }        
        Blend SrcAlpha OneMinusSrcAlpha
    	ZWrite Off 
		LOD 200
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
           
            CGPROGRAM
            #pragma vertex SceneVert
            #pragma fragment SceneFrag   

			#define SIMPLELIGHT_ON
			#define DOD_FOG_LINEAR
			#define TRANSPARENT
			#define DOD_PLATFORM_MOBILE
			#pragma multi_compile_fwdbase

//			#pragma multi_compile DOD_PLATFORM_PC DOD_PLATFORM_MOBILE
			#pragma multi_compile_instancing
			#include "DodScenePbsCore.cginc"

            ENDCG
        }

    }Fallback "Dodjoy/FallBack"
}
