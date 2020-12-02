// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Dodjoy/PostProcess/ColorGrading"
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Brightness;
            fixed _Saturation;
            fixed _Contrast;
			fixed _R;
			fixed _G;
			fixed _B;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float3 ContrastSaturationBrightness(float3 color, float brt, float sat, float con) 
            {
                // Increase or decrease these values to  
                // adjust r, g and b color channels separately  
                float avgLumR = 0.5;
                float avgLumG = 0.5;
                float avgLumB = 0.5;

                // Luminance coefficients for getting luminance from the image  
                float3 LuminanceCoeff = float3 (0.2125, 0.7154, 0.0721);

                // Operation for brightmess  
                float3 avgLumin = float3 (avgLumR, avgLumG, avgLumB);
                float3 brtColor = color * brt;
                float intensityf = dot(brtColor, LuminanceCoeff);
                float3 intensity = float3 (intensityf, intensityf, intensityf);

                // Operation for saturation  
                float3 satColor = lerp(intensity, brtColor, sat);

                // Operation for contrast  
                float3 conColor = lerp(avgLumin, satColor, con);

                return conColor;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
				col.r += _R;
				col.g += _G;
				col.b += _B;

                col.rgb = ContrastSaturationBrightness(col, _Brightness, _Saturation, _Contrast);
                return col;
            }
            ENDCG
        }
    }
}