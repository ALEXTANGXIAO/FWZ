Shader "Dodjoy/Scene/SceneLightProbeFade"
{
   Properties
    {
		_MainColor("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }		
		Cull Off
		LOD 600
        Pass
        {
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag   

			#pragma multi_compile_fwdbase
			#define HIGHTFOG
			#define LINEARCOLOR
			#define DOD_FOG_LINEAR
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "DodFog.cginc"
			#include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

			half clipMatrix(half2 pos, half alpha) {
			pos *= _ScreenParams.xy;
			half Thresholds[16] =
			{
				1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
				13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
				4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
				16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
			};
			int index = int(fmod(pos.x,4)) + int(fmod(pos.y,4)) * 4;
			return alpha - Thresholds[index];
			}
			void doClip(float2 pos, float alpha) {
				clip(clipMatrix(pos, alpha));
			}

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                fixed3 SHLighting : COLOR;
				float3 worldPos : TEXCOORD1;
				float4 scrpos : TEXCOORD3;
				DOD_FOG_COORDS(2)
            };
            sampler2D _MainTex;			
            float4 _MainTex_ST;	
			float4 _MainColor;
			half _startTime;
            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.SHLighting = ShadeSH9(float4(worldNormal,1));
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.scrpos = ComputeScreenPos(o.vertex);
				DOD_TRANSFER_FOG(o.fogCoord, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
				col *= col;
                col *= _MainColor;
                col.rgb *= i.SHLighting;
				float2 screenpos = i.scrpos.xy/i.scrpos.w;
				doClip(screenpos,_startTime);
				DOD_APPLY_FOG(i.fogCoord, i.worldPos, col.rgb);
				col.rgb = pow(col.rgb,0.5);
                return col;
            }
            ENDCG
        }
    }
	SubShader
    {
        Tags { "RenderType"="Opaque" }		
		Cull Off
		LOD 300
        Pass
        {
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag   
			#pragma multi_compile_fwdbase
			#define DOD_FOG_LINEAR
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "DodFog.cginc"
			#include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
				float4 scrpos : TEXCOORD3;
            };
			half clipMatrix(half2 pos, half alpha) {
			pos *= _ScreenParams.xy;
			half Thresholds[16] =
			{
				1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
				13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
				4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
				16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
			};
			int index = int(fmod(pos.x,4)) + int(fmod(pos.y,4)) * 4;
			return alpha - Thresholds[index];
			}
			void doClip(float2 pos, float alpha) {
				clip(clipMatrix(pos, alpha));
			}

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                fixed3 SHLighting : COLOR;
				float3 worldPos : TEXCOORD1;
				float4 scrpos : TEXCOORD3;
				DOD_FOG_COORDS(2)
            };
            sampler2D _MainTex;			
            float4 _MainTex_ST;	
			float4 _MainColor;
			half _startTime;
            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.SHLighting = ShadeSH9(float4(worldNormal,1));
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.scrpos = ComputeScreenPos(o.vertex);
				DOD_TRANSFER_FOG(o.fogCoord, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                col *= _MainColor;
                col.rgb *= i.SHLighting;
				float2 screenpos = i.scrpos.xy/i.scrpos.w;
				doClip(screenpos,_startTime);
				DOD_APPLY_FOG(i.fogCoord, i.worldPos, col.rgb);
                return col;
            }
            ENDCG
        }
    }
	SubShader
    {
        Tags { "RenderType"="Opaque" }		
		Cull Off
		LOD 200
        Pass
        {
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag   

			#pragma multi_compile_fwdbase

			#define DOD_FOG_LINEAR
			#define DOD_PLATFORM_MOBILE
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "DodFog.cginc"
			#include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };
			half clipMatrix(half2 pos, half alpha) {
			pos *= _ScreenParams.xy;
			half Thresholds[16] =
			{
				1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
				13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
				4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
				16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
			};
			int index = int(fmod(pos.x,4)) + int(fmod(pos.y,4)) * 4;
			return alpha - Thresholds[index];
			}
			void doClip(float2 pos, float alpha) {
				clip(clipMatrix(pos, alpha));
			}

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                fixed3 SHLighting : COLOR;
				float3 worldPos : TEXCOORD1;
				float4 scrpos : TEXCOORD3;
				DOD_FOG_COORDS(2)
            };
            sampler2D _MainTex;			
            float4 _MainTex_ST;	
			float4 _MainColor;
			half _startTime;
		
            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.SHLighting = ShadeSH9(float4(worldNormal,1));
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.scrpos = ComputeScreenPos(o.vertex);
				DOD_TRANSFER_FOG(o.fogCoord, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                col *= _MainColor;
                col.rgb *= i.SHLighting;
				float2 screenpos = i.scrpos.xy/i.scrpos.w;
				doClip(screenpos,_startTime);
				DOD_APPLY_FOG(i.fogCoord, i.worldPos, col.rgb);
                return col;
            }
            ENDCG
        }
    }Fallback "Dodjoy/FallBack"
}
