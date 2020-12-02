
Shader "Dodjoy/PostProcess/ScreenWave" {

    Properties {
        _MainTex ("Background", 2D) = "" {} 

    }

    SubShader {
        Tags { "RenderType" = "Opaque"}
        Pass {

            Cull Off
            AlphaTest Off
            Lighting Off
            ColorMask RGBA
            Blend Off

            CGPROGRAM
            #pragma target 2.0
            #pragma fragment frag
            #pragma vertex vert
            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;
			
			uniform float _WaveDis;
			float4 _MainTex_ST;

            struct AppData {
                float4 vertex : POSITION;
                half2 texcoord : TEXCOORD0;
            };

            struct VTF {
                float4 pos : POSITION;
                half2 uv : TEXCOORD0;
            };

            VTF vert(AppData v) {
                VTF o;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            
            fixed4 frag(VTF i) : COLOR {        
				float2 vp = float2(0.5, 0.5) - i.uv;
				float dis = sqrt(vp.x * vp.x + vp.y * vp.y);
				float sinFactor = sin(dis * 70 + _Time.y * -30) * 0.02;
				float discardFactor = clamp(0.4 - abs(_WaveDis - dis), 0, 1);
				float2 dv1 = normalize(vp);
				float2 offset = dv1  * sinFactor * discardFactor;
                return tex2D(_MainTex, i.uv + offset);
            }

            ENDCG
        }
    }
}