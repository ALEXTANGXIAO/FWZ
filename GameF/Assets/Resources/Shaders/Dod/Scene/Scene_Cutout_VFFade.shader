// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Dodjoy/Scene/Scene_Cutout_VFFade"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_FrontColor("Front Color", Color) = (1, 1, 1, 1)
		_BackColor("BackColor", Color) = (0.3, 0.3, 0.3, 1)
		_LightScale("LightScale",Range(0,4.0)) = 1.4
		[Toggle(SWING_ON)]_SwingOn("Leaf Swing", float) = 0
		
		_Pos("Position",Vector) = (0,0,0,0)
		_Direction("Swing Direction", Vector) = (0,0,0,0)
		_TimeScale("Time Scale", float) = 1
		_TimeDelay("TimeDelay",float) = 1
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue" = "AlphaTest""IgnoreProjector" = "true"}
		
		Cull Off
		LOD 600
        Pass
        {
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag   

			#pragma multi_compile LIGHTMAP_ON
			#pragma multi_compile_fwdbase

			#define DOD_SUN_ON
			#define DOD_FOG_LINEAR
			#define HIGHTFOG
			#define LINEARCOLOR
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "DodFog.cginc"
			#include "AutoLight.cginc"

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

            struct a2v
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
				float2 texcoord2 : TEXCOORD1;
				fixed4 color : COLOR;  //修改 缺少顶点色输入
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
				DOD_FOG_COORDS(3)
#ifdef LIGHTMAP_ON
				float2 uvLM : TEXCOORD4;
#endif			
				float4 scrpos : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			fixed3 _FrontColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
			fixed _Cutoff;
			fixed4 _BackColor;
			fixed _LightScale;
			half4 _Pos;
			half4 _Direction;
			half _TimeScale;
			half _TimeDelay;
			half _startTime;

            v2f vert (a2v v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
#ifdef LIGHTMAP_ON
				o.uvLM = v.texcoord2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
				o.scrpos = ComputeScreenPos(o.pos);
				DOD_TRANSFER_FOG(o.fogCoord, v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 col = tex2D(_MainTex, i.uv);
				clip(col.a - _Cutoff);
				col.rgb *= col.rgb;
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldPos = normalize(i.worldPos);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 Ndl = max(0.0,dot(worldNormal,worldLightDir));               


#ifdef LIGHTMAP_ON
				fixed3 lm = (DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uvLM)));
				fixed backatten = UnitySampleBakedOcclusion(i.uvLM,worldPos);
				fixed3 lmcolor = (lm + max(0.1, Ndl)*_LightColor0.rgb * backatten) * _LightScale;
				fixed3 Bkcolor = lerp(_BackColor,0,clamp(0,1,lm.r-0.2));
				col.rgb *= lmcolor*_FrontColor + Bkcolor;
#endif
				fixed4 finalColor = col;
				finalColor.a = col.a;

				float2 screenpos = i.scrpos.xy/i.scrpos.w;
				doClip(screenpos,_startTime);

				DOD_APPLY_FOG(i.fogCoord, i.worldPos, finalColor.rgb);
				finalColor.rgb = pow(finalColor.rgb,0.5);
                return finalColor;
            }
            ENDCG
        }
    }

	SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue" = "AlphaTest""IgnoreProjector" = "true"}
		
		Cull Off
		LOD 300
        Pass
        {
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag   
			#pragma multi_compile LIGHTMAP_ON
			#pragma multi_compile_fwdbase
			#define DOD_FOG_LINEAR
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "DodFog.cginc"
			#include "AutoLight.cginc"

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

            struct a2v
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
				float2 texcoord2 : TEXCOORD1;
				fixed4 color : COLOR;  //修改 缺少顶点色输入
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
				DOD_FOG_COORDS(3)
#ifdef LIGHTMAP_ON
				float2 uvLM : TEXCOORD4;
#endif			
				float4 scrpos : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			fixed3 _FrontColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
			fixed _Cutoff;
			fixed4 _BackColor;
			fixed _LightScale;
			half4 _Pos;
			half4 _Direction;
			half _TimeScale;
			half _TimeDelay;
			half _startTime;

            v2f vert (a2v v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
#ifdef LIGHTMAP_ON
				o.uvLM = v.texcoord2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
				o.scrpos = ComputeScreenPos(o.pos);
				DOD_TRANSFER_FOG(o.fogCoord, v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 col = tex2D(_MainTex, i.uv);
				clip(col.a - _Cutoff);
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldPos = normalize(i.worldPos);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 Ndl = max(0.0,dot(worldNormal,worldLightDir));               
#ifdef LIGHTMAP_ON
				fixed3 lm = (DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uvLM)));
				fixed backatten = UnitySampleBakedOcclusion(i.uvLM,worldPos);
				fixed3 lmcolor = (lm + max(0.1, Ndl)*_LightColor0.rgb * backatten) * _LightScale;
				fixed3 Bkcolor = lerp(_BackColor,0,clamp(0,1,lm.r-0.2));
				col.rgb *= lmcolor*_FrontColor + Bkcolor;
#endif
				fixed4 finalColor = col;
				finalColor.a = col.a;
				float2 screenpos = i.scrpos.xy/i.scrpos.w;
				doClip(screenpos,_startTime);
				DOD_APPLY_FOG(i.fogCoord, i.worldPos, finalColor.rgb);

                return finalColor;
            }
            ENDCG
        }
    }

	SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue" = "AlphaTest""IgnoreProjector" = "true"}
		
		Cull Off
		LOD 200
        Pass
        {
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag   

			#pragma multi_compile LIGHTMAP_ON
			#pragma multi_compile_fwdbase

			#define DOD_FOG_LINEAR
			#pragma multi_compile_instancing

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "DodFog.cginc"
			#include "AutoLight.cginc"

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

            struct a2v
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
				float2 texcoord2 : TEXCOORD1;
				fixed4 color : COLOR;  //修改 缺少顶点色输入
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
				DOD_FOG_COORDS(3)
#ifdef LIGHTMAP_ON
				float2 uvLM : TEXCOORD4;
#endif			
				float4 scrpos : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			fixed _Cutoff;
			half4 _Pos;
			half _startTime;

            v2f vert (a2v v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
#ifdef LIGHTMAP_ON
				o.uvLM = v.texcoord2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
				DOD_TRANSFER_FOG(o.fogCoord, v.vertex);
				o.scrpos = ComputeScreenPos(o.pos);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 col = tex2D(_MainTex, i.uv);
				clip(col.a - _Cutoff);          
#ifdef LIGHTMAP_ON
				fixed3 lm = (DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uvLM)));
				col.rgb *= lm;
#endif
				fixed4 finalColor = col;
				finalColor.a = col.a;
				float2 screenpos = i.scrpos.xy/i.scrpos.w;
				doClip(screenpos,_startTime);
				DOD_APPLY_FOG(i.fogCoord, i.worldPos, finalColor.rgb);

                return finalColor;
            }
            ENDCG
        }
    }
	
}
