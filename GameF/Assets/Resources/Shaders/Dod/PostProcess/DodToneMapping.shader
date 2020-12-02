Shader "Dodjoy/PostProcess/ToneMapping"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			half _luminance;
			float _GammaIN;
			float3 ACESToneMapping(float3 color, float adapted_lum)
			{
				const float A = 2.51f;
				const float B = 0.03f;
				const float C = 2.43f;
				const float D = 0.59f;
				const float E = 0.14f;

				color *= adapted_lum;
				return clamp((color * (A * color + B)) / (color * (C * color + D) + E),0.0,1.0);
			}

			float3 PositivePow(float3 base, float3 power)
			{
				return pow(max(abs(base), float3(1.192092896e-07, 1.192092896e-07, 1.192092896e-07)), power);
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
				col.rgb = col.rgb * (col.rgb * (col.rgb * 0.305306011 + 0.682171111) + 0.012522878);
				col.rgb = clamp(col.rgb,0.0,2.8);
				col.rgb = ACESToneMapping(col.rgb, 0.5);
				col.rgb =  max(PositivePow(col.rgb, _GammaIN), 0.0);

				return col;
			
            }
            ENDCG
        }
    }
}
