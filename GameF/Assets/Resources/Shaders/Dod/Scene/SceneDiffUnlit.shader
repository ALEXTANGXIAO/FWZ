// customLightmap
// by baogang 

Shader "Dodjoy/Scene/SceneDiffUnlit"
{
    Properties
    {
		_MainColor("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
	

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" 
			}
		
		Cull Off

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
			#pragma multi_compile LIGHTMAP_ON
			#pragma multi_compile SHADOWS_SHADOWMASK;
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "DodFog.cginc"
			#include "AutoLight.cginc"
	//		#include "DodScenePbsCore.cginc"

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
				float3 viewDir : TEXCOORD5;
#ifdef LIGHTMAP_ON
				float2 uvLM : TEXCOORD4;
#endif	
				DOD_FOG_COORDS(3)			
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            sampler2D _MainTex;
			
            float4 _MainTex_ST;
	
			float4 _MainColor;
		

            v2f vert (a2v v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
//				o.viewDir = ObjSpaceViewDir(v.vertex);
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.worldPos);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
#ifdef LIGHTMAP_ON
				o.uvLM = v.texcoord2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
				DOD_TRANSFER_FOG(o.fogCoord, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				half4 col = tex2D(_MainTex, i.uv);
//				col *= col;
				fixed4 finalColor;
				finalColor.rgb=col.rgb*_MainColor * _LightColor0.rgb;
#ifdef LIGHTMAP_ON
				half4 lm ;
				half4 indirectColor;
				indirectColor = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uvLM);
				lm = indirectColor*4.0;
				finalColor.rgb=col.rgb*_MainColor.rgb *indirectColor.rgb;
#endif
				finalColor.a = col.a;
				//UNITY_APPLY_FOG(i.fogCoord, finalColor);
				DOD_APPLY_FOG(i.fogCoord, i.worldPos, finalColor.rgb);
				finalColor.rgb = pow(finalColor.rgb,0.5);
				
                return finalColor;
            }
            ENDCG
        }
    }
	Fallback "Dodjoy/FallBack"
}
