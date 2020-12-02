
Shader "Dodjoy/Scene/Scene_Water_GlassReflection"       ////Scene_Water_L更改名称为Scene_Water_GlassReflection
{
    Properties
    {
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Opaque"}

		//折射图
		GrabPass
		{
			"_RefractionTex"
		}
		
        Pass
        {
			Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile DOD_FOG_NONE DOD_FOG_LINEAR DOD_FOG_EXP DOD_FOG_EXP2

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "CustomFog.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				
            };

            struct v2f
            {
				float4 pos : SV_POSITION;

				float4 screenPos : TEXCOORD0;
				float4 bumpCoords : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				CUSTOM_FOG_COORDS(3)
            };

			sampler2D _WaveTex;
			float _WaveScale;
			float4 _WaveDireciotn;
			float4 _WaveTiling;

			sampler2D _ReflectionTex;
			sampler2D _RefractionTex;
			float _RefractionOffset;

			float _SpecScale;
			float _Gloss;

			samplerCUBE _ReflectionTex2;

			float3 PerPixelNormal(sampler2D bumpMap, float4 coords, float bumpStrength)
			{
				float2 bump = UnpackNormal(tex2D(bumpMap, coords.xy));
				bump += UnpackNormal(tex2D(bumpMap, coords.xy * 2));
				bump += UnpackNormal(tex2D(bumpMap, coords.xy * 8));
 
				float3 worldNormal = float3(0,0,0);
				worldNormal.xz = bump.xy * bumpStrength;
				worldNormal.y = 1;
				return worldNormal;
			}

			half FastFresnel(float3 I, float3 N, float R0)
			{
				float icosIN = saturate(1 - dot(I, N));
				float i2 = icosIN * icosIN;
				float i4 = i2 * i2;
				return R0 + (1 - R0) * (i4 * icosIN);
			}

            v2f vert (appdata v)
            {
                v2f o;		
                o.pos = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.pos);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				//法线uv动画
				o.bumpCoords = (o.worldPos.xzxz + _Time.yyyy * _WaveDireciotn.xyzw) * _WaveTiling.xyzw;

				CUSTOM_TRANSFER_FOG(o.fogCoord, v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float3 worldPos = i.worldPos;
				float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                float3 viewDir = normalize(worldPos - _WorldSpaceCameraPos.xyz);
				float3 halfDir = normalize(-viewDir + lightDir);

				float3 worldNormal = normalize(PerPixelNormal(_WaveTex,i.bumpCoords, _WaveScale));
				float2 offsets = worldNormal.xz * viewDir.y;
				float2 screenUV = i.screenPos.xy / i.screenPos.w + offsets * _RefractionOffset;

				float3 refrColor = tex2D(_RefractionTex, screenUV);

				float3 reflColor = tex2D(_ReflectionTex, screenUV);
				
				half3 spec = pow(max(0, dot(halfDir, worldNormal)), _Gloss);
				half3 specColor = spec * _LightColor0.rgb * _SpecScale;
				
				float fresnel = FastFresnel(-viewDir, worldNormal, 0.02f);
				fixed3 finalColor = reflColor * fresnel + refrColor * (1 - fresnel) + specColor;

				CUSTOM_APPLY_FOG(i.fogCoord, worldPos, finalColor);

				return fixed4(finalColor, 1);
            }
            ENDCG
        }
    }
}
