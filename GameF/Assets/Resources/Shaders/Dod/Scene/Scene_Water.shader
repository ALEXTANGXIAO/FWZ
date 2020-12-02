
Shader "Dodjoy/Scene/Scene_Water" 
{
	Properties
    {
        _Color("WaterColor(RGB)", color) = (1,1,1,1)
		_DepthColor("DepthColor(RGB)", color) = (1,1,1,1)
        [NoScaleOffset]
		_WaveTex("BumpTex(RGB)", 2D) = "bump" {} 
        [NoScaleOffset]
		_ReflectionTex("ReflectMap(RGB)", 2D) = "while" {}
		_WaterDepth("WaterDepth", Range(0.001, 3)) = 0.1
		_BumpScale("BumpScale", range(0, 0.2)) = 0.2
        _BumpTile1("BumpTile1", Range(0.01, 1)) = 0.02
        _BumpTile2("BumpTile2", Range(0.01, 1)) = 0.02
        _ReflecScale("ReflecScale", Range(1, 2)) = 1.2
        _ReflecScale2("ReflecScale2", Range(1, 2)) = 1.2
		_GlossScale("GlossScale", Range(0, 2)) = 1
		_Gloss("Gloss", Range(8, 64)) = 8      
		_BumpDireciotn("BumpDirection", vector) = (1,1,1,-1)
    }
    SubShader
    {		
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
		LOD 600
        Pass
        {
            Tags{ "LightMode"="ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

			#include "DodFog.cginc"			
			#define DOD_FOG_LINEAR

            struct appdata
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float4 bumpCoords : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
				DOD_FOG_COORDS(4)
            };

            fixed4 _Color, _DepthColor;
            sampler2D _WaveTex, _ReflectionTex;
            half4 _BumpDireciotn;
            half _GlossScale, _Gloss, _WaterDepth, _BumpScale;
            half _BumpTile1, _BumpTile2, _ReflecScale, _ReflecScale2;

            half3 PerPixelNormal(sampler2D bumpMap, half4 coords, half4 bumpStrength)
            {
                half2 bump = UnpackNormal(tex2D(bumpMap, coords.xy));
                bump += UnpackNormal(tex2D(bumpMap, coords.zw));
            
                half3 worldNormal = half3(0,0,0);
                worldNormal.xz = bump.xy * bumpStrength;
                worldNormal.y = 1;
                return worldNormal;
            }

            half FastFresnel(half3 I, half3 N, float R0)
            {
                half icosIN = saturate(1 - dot(I, N) / _ReflecScale2);
                half i2 = icosIN * icosIN;
                return R0 + (1 - R0) * (i2 * icosIN);
            }

            v2f vert (appdata v)
            {
                v2f o = (v2f) 0;    

                o.pos = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.pos);
                o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldPos.w = v.color.r;                
                o.bumpCoords = (o.worldPos.xzxz + _Time.yyyy * _BumpDireciotn.xyzw) * half4 (_BumpTile1, _BumpTile1, _BumpTile2, _BumpTile2);
                DOD_TRANSFER_FOG(o.fogCoord, v.vertex);
				
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 worldPos = i.worldPos;
                half3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                half3 viewDir = normalize(worldPos - _WorldSpaceCameraPos.xyz);
                half3 halfDir = normalize(-viewDir + lightDir);
                half3 worldNormal = normalize(PerPixelNormal(_WaveTex, i.bumpCoords, _BumpScale));
            
				//AlphaControl
                half depth = (1 - i.worldPos.w) / _WaterDepth * 2;
                depth = saturate(depth);
                
                //Reflraction
                half3 graColor = lerp(_Color, _DepthColor, depth);

                //Reflection
                half3 reflUV = reflect(viewDir, worldNormal);
                half3 reflColor = tex2D(_ReflectionTex, reflUV) * _ReflecScale;
                half fresnel = FastFresnel(-viewDir, worldNormal, 0.02);
                
                //Specular
                half3 spec = pow(max(0, dot(halfDir, worldNormal)), _Gloss);
                half3 specColor = spec * _LightColor0.rgb * _GlossScale * fresnel;

                fixed3 finalColor = reflColor * fresnel + graColor * (1 - fresnel) + specColor;

				#if defined (DOD_FOG_LINEAR) 
				DOD_APPLY_FOG(i.fogCoord, worldPos, finalColor);
				depth *= saturate((i.fogCoord.x));
				finalColor *= depth;	
				#endif

                return fixed4(finalColor, depth);
            }
            ENDCG
        }
    }

	SubShader
    {		
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
		LOD 300
        Pass
        {
            Tags{ "LightMode"="ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

			#include "DodFog.cginc"			
			#define DOD_FOG_LINEAR

            struct appdata
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 bumpCoords : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
				DOD_FOG_COORDS(4)
            };

            fixed4 _Color, _DepthColor;
            sampler2D _WaveTex, _ReflectionTex;
            half4 _BumpDireciotn;
            half _GlossScale, _Gloss, _WaterDepth, _BumpScale;
            half _BumpTile1, _BumpTile2, _ReflecScale, _ReflecScale2;

            half3 PerPixelNormal(sampler2D bumpMap, half4 coords, half4 bumpStrength)
            {
                half2 bump = UnpackNormal(tex2D(bumpMap, coords.xy));
                bump += UnpackNormal(tex2D(bumpMap, coords.zw));
            
                half3 worldNormal = half3(0,0,0);
                worldNormal.xz = bump.xy * bumpStrength;
                worldNormal.y = 1;
                return worldNormal;
            }

            half FastFresnel(half3 I, half3 N, float R0)
            {
                half icosIN = saturate(1 - dot(I, N) / _ReflecScale2);
                half i2 = icosIN * icosIN;
                return R0 + (1 - R0) * (i2 * icosIN);
            }

            v2f vert (appdata v)
            {
                v2f o = (v2f) 0;    

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldPos.w = v.color.r;                
                o.bumpCoords = (o.worldPos.xzxz + _Time.yyyy * _BumpDireciotn.xyzw) * half4 (_BumpTile1, _BumpTile1, _BumpTile2, _BumpTile2);
                DOD_TRANSFER_FOG(o.fogCoord, v.vertex);
				
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 worldPos = i.worldPos;
                half3 viewDir = normalize(worldPos - _WorldSpaceCameraPos.xyz);
                half3 worldNormal = normalize(PerPixelNormal(_WaveTex, i.bumpCoords, _BumpScale));
            
				//AlphaControl
                half depth = (1 - i.worldPos.w) / _WaterDepth * 2;
                depth = saturate(depth);
                
                //Reflraction
                half3 graColor = lerp(_Color, _DepthColor, depth);

                //Reflection
                half3 reflUV = reflect(viewDir, worldNormal);
                half3 reflColor = tex2D(_ReflectionTex, reflUV) * _ReflecScale;
                half fresnel = FastFresnel(-viewDir, worldNormal, 0.02);

                fixed3 finalColor = reflColor * fresnel + graColor * (1 - fresnel);

				#if defined (DOD_FOG_LINEAR) 
				DOD_APPLY_FOG(i.fogCoord, worldPos, finalColor);
				depth *= saturate((i.fogCoord.x));
				finalColor *= depth;	
				#endif

                return fixed4(finalColor, depth);
            }
            ENDCG
        }
    }

	SubShader
    {		
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
		LOD 100
        Pass
        {
            Tags{ "LightMode"="ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

			#include "DodFog.cginc"			
			#define DOD_FOG_LINEAR

            struct appdata
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 bumpCoords : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
				DOD_FOG_COORDS(4)
            };

            fixed4 _Color, _DepthColor;
            sampler2D _WaveTex, _ReflectionTex;
            half4 _BumpDireciotn;
            half _GlossScale, _Gloss, _WaterDepth, _BumpScale;
            half _BumpTile1, _BumpTile2, _ReflecScale, _ReflecScale2;

            half3 PerPixelNormal(sampler2D bumpMap, half4 coords, half4 bumpStrength)
            {
                half2 bump = UnpackNormal(tex2D(bumpMap, coords.xy));
                bump += UnpackNormal(tex2D(bumpMap, coords.zw));
            
                half3 worldNormal = half3(0,0,0);
                worldNormal.xz = bump.xy * bumpStrength;
                worldNormal.y = 1;
                return worldNormal;
            }
            
            v2f vert (appdata v)
            {
                v2f o = (v2f) 0;    

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldPos.w = v.color.r;                
                o.bumpCoords = (o.worldPos.xzxz + _Time.yyyy * _BumpDireciotn.xyzw) * half4 (_BumpTile1, _BumpTile1, _BumpTile2, _BumpTile2);
                DOD_TRANSFER_FOG(o.fogCoord, v.vertex);
				
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 worldPos = i.worldPos;
                half3 viewDir = normalize(worldPos - _WorldSpaceCameraPos.xyz);
                half3 worldNormal = normalize(PerPixelNormal(_WaveTex, i.bumpCoords, _BumpScale));
            
				//AlphaControl
                half depth = (1 - i.worldPos.w) / _WaterDepth * 2;
                depth = saturate(depth);
                
                //Reflraction
                half3 graColor = lerp(_Color, _DepthColor, depth);

                //Reflection
                half3 reflUV = reflect(viewDir, worldNormal);
                half3 reflColor = tex2D(_ReflectionTex, reflUV) * _ReflecScale;            
                

                fixed3 finalColor = reflColor * graColor * _ReflecScale2;

                #if defined (DOD_FOG_LINEAR) 
				DOD_APPLY_FOG(i.fogCoord, worldPos, finalColor);
				depth *= saturate((i.fogCoord.x));
				finalColor *= depth;	
				#endif

                return fixed4(finalColor, depth);
            }
            ENDCG
        }
    }
}
// 	Properties
//     {
// 		_Color("Water Color", color) = (1,1,1,1)
// 		_DepthColor("Depth Color", color) = (1,1,1,1)
// 		_Depth("Water Depth", Range(0, 1)) = 0.1
// 		_FresnelDepth("Fresnel Depth", Range(0, 1)) = 0.1

// 		_WaveTex("Bump Tex", 2D) = "bump" {}
// 		_WaveScale("Bump Scale", range(0, 1)) = 0.2
// 		_WaveDireciotn("Bump direction", vector) = (1,1,1,-1)
// 		_WaveTiling("Bump tiling", vector) = (0.0625, 0.0625, 0.0625, 0.0625)
// 		_ReflectionTex("Reflect map", 2D) = "while" {}
// 		_RefractionOffset("Refraction offset", Range(0, 0.1)) = 0.05
// 		_SpecScale("Specular Scale", Range(0, 5)) = 1
// 		_Gloss("Gloss", Range(0, 256)) = 8
		
//     }
//     SubShader
//     {
//         Tags { "Queue"="Transparent" "RenderType"="Transparent"}
// 		LOD 600
//         Pass
//         {
// 			Tags{"LightMode"="ForwardBase"}
// 			Blend SrcAlpha OneMinusSrcAlpha
//             CGPROGRAM
//             #pragma vertex Watervert
//             #pragma fragment Waterfrag
// 			#define DOD_FOG_LINEAR
// 			#define BUMPANIM_ON
// 			#define REFRACTION_ON
// 			#define FRESNEL_ON
// 			#define SPEC_ON
// 			#include "DodWaterCore.cginc"

//             ENDCG
//         }
//     }
// 	SubShader
//     {
//         Tags { "Queue"="Transparent" "RenderType"="Transparent"}
// 		LOD 300
//         Pass
//         {
// 			Tags{"LightMode"="ForwardBase"}
//             CGPROGRAM
//             #pragma vertex Watervert
//             #pragma fragment Waterfrag
// 			#define DOD_FOG_LINEAR
// 			#define BUMPANIM_ON
// 			#define REFRACTION_ON
// 			#define FRESNEL_ON
// //			#define SPEC_ON
// 			#include "DodWaterCore.cginc"

//             ENDCG
//         }
//     }
// 	SubShader
//     {
//         Tags { "Queue"="Transparent" "RenderType"="Transparent"}
// 		LOD 100
		
//         Pass
//         {
// 			Tags{"LightMode"="ForwardBase"}
//             CGPROGRAM
//             #pragma vertex Watervert
//             #pragma fragment Waterfrag
// 			#define DOD_FOG_LINEAR
// 			#define BUMPANIM_ON
// //			#define REFRACTION_ON
// //			#define FRESNEL_ON
// //			#define SPEC_ON
// 			#include "DodWaterCore.cginc"

//             ENDCG
//         }
//     }
// }
