Shader "Dodjoy/Scene/Scene_Transparent"
{
    Properties
    {
		_Color("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
		_MaskTex("Mask(R-Specular, G-Emission)", 2D) = "black" {}
		_Specular("Specular Color", Color) = (1,1,1,1)
		_Gloss("Gloss", Range(8.0, 256.0)) = 8.0
		_SpecularScale("Specular Scale", Float) = 1
		_Transparency("Transparency", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
					
		Pass{
			/*
			Tags { "LightMode" = "ForwardBase"}
			
			Cull Front
			ZWrite On

			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Transparency;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				fixed4 texColor = tex2D(_MainTex, i.uv);
				
				fixed3 albedo = texColor.rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				
				return fixed4(ambient + diffuse, texColor.a * _Transparency);
			}
			
			ENDCG
			*/

			ZWrite On
			ColorMask 0
		}

        Pass
        {
			Tags{"LightMde" = "ForwardBase"}
			
			Cull off 
			ZWrite off
			Blend  SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			

			#pragma multi_compile DOD_FOG_NONE DOD_FOG_LINEAR DOD_FOG_EXP DOD_FOG_EXP2

			#pragma multi_compile __ LIGHTMAP_ON

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "CustomFog.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
#ifdef LIGHTMAP_ON
				float2 uvLM : TEXCOORD1;
#endif
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
#ifdef LIGHTMAP_ON
				float2 uvLM : TEXCOORD3;
#endif
				CUSTOM_FOG_COORDS(4)
            };

			fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _MaskTex;
			fixed4 _Specular;
			half _Gloss;
			half _SpecularScale;
			half _Transparency;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
#ifdef LIGHTMAP_ON
				o.uvLM = v.uvLM.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif

				CUSTOM_TRANSFER_FOG(o.fogCoord, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				half3 worldPos = normalize(i.worldPos);
				half3 worldNormal = normalize(i.worldNormal);
				half3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				half3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				half3 halfDir = normalize(viewDir + worldLightDir);
				
                fixed4 col = tex2D(_MainTex, i.uv);
				fixed3 albedo = col.rgb * _Color.rgb;
				fixed4 mask = tex2D(_MaskTex, i.uv);

				fixed3 finalColor = 1.0;
#ifdef LIGHTMAP_ON
				fixed3 lm = (DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uvLM)));
				finalColor = albedo * (lm / 0.85);
#else
				fixed3 diff = albedo * (dot(worldNormal, worldLightDir) * 0.5 +0.5);
				diff = (diff + 0.5) * 0.5;
				finalColor = _LightColor0.rgb * albedo * diff;

#if UNITY_SHOULD_SAMPLE_SH
				fixed3 ambient = max(half3(0, 0, 0), ShadeSH9(half4(worldNormal, 1.0)));
				finalColor += ambient * col * 0.5;
#endif

#endif
				fixed3 emission = mask.g * albedo;
				finalColor += emission;

				fixed3 speColor = _LightColor0 * _Specular.rgb * pow((dot(worldNormal, halfDir)* 0.5 + 0.5), _Gloss);
				fixed3 specular = speColor * _SpecularScale * mask.r;
				finalColor += specular;

                // apply fog
				CUSTOM_APPLY_FOG(i.fogCoord, worldPos, finalColor.rgb);
                return fixed4(finalColor, col.a * _Transparency);
            }
            ENDCG
        }
    }
	Fallback "Dodjoy/FallBack"
}
