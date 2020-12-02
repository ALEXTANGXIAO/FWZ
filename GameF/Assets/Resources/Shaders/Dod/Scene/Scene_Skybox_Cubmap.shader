Shader "Dodjoy/Scene/Scene_Skybox_Cubmap"
{
    Properties
    {
		_Tint("Tint Color", color) = (0.5, 0.5, 0.5, 1.0)
        [Gamma]_Exposure("Exposure", range(0, 8)) = 1.0
		_Rotation("Rotation", range(0, 360)) = 0
		_Cubemap("Cubemap (HDR)", Cube) = "grey" {}
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
		Cull Off
		ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile __ DOD_FOG_NONE
			#define FOG_SKY_BOX

            #include "UnityCG.cginc"
			#include "CustomFog.cginc"
			
            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
				CUSTOM_FOG_COORDS(1)
				float4 worldPos : TEXCOORD2;
            };

			half4 _Tint;
			half _Exposure;
			float _Rotation;
			samplerCUBE _Cubemap;
			half4 _Cubemap_HDR;
			

			float4 RotateAroundYInDegrees(float4 vertex, float degrees)
			{
				float alpha = degrees * UNITY_PI / 180.0;
				float sina, cosa;
				sincos(alpha, sina, cosa);
				float2x2 m = float2x2(cosa, -sina, sina, cosa);
				return float4(mul(m, vertex.xz), vertex.yw).xzyw;
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(RotateAroundYInDegrees( v.vertex, _Rotation));
				o.uv = v.uv;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				CUSTOM_TRANSFER_FOG(o.fogCoord, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				half4 tex = texCUBE(_Cubemap, i.uv);
				half3 c = DecodeHDR(tex, _Cubemap_HDR);
				c = c * _Tint.rgb * unity_ColorSpaceDouble.rgb;
				c *= _Exposure;

				CUSTOM_APPLY_FOG(i.fogCoord, i.worldPos, c);
				return half4(c, 1);
            }
            ENDCG
        }
    }
}
