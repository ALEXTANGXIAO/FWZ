Shader "Dodjoy/PostProcess/Vignette"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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

			float _CenterX;
			float _CenterY;
			float _Intensity;
			float _Smoothness;
			float _Roundness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float vignette = _Intensity - _Smoothness * (dot(i.uv - _CenterX, i.uv - _CenterY) * _Roundness);

                fixed3 col = tex2D(_MainTex, i.uv);
                return fixed4(col * vignette, 1.0);
            }
            ENDCG
        }
    }
}
