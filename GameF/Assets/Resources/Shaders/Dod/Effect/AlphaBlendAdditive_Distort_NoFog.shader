﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Dodjoy/Effect/AlphaBlendAdditive_Distort_NoFog" {
    Properties {
        _TintColor ("Tint Color", Color) = (1,1,1,1)
        _MainTex ("MainTex", 2D) = "white" {}
        _DisortTex ("niuqu_tex", 2D) = "white" {}
        _DistortStrangth ("QD", Float ) = 0.05
        _GLOW ("GLOW", Float ) = 2
        _SpeedV ("V速度", Float ) = 0
        _SpeedU ("U速度", Float ) = 0

		_TintColor2("Tint Color2", Color) = (1,1,1,1)
		_MainTex2("MainTex2", 2D) = "white" {}
		_DisortTex2("niuqu_tex2", 2D) = "white" {}
		_DistortStrangth2("QD2", Float) = 0.05
		_GLOW2("GLOW2", Float) = 2
		_SpeedV2("V速度2", Float) = 0
		_SpeedU2("U速度2", Float) = 0
		_AlphaScale("Alpha Scale", Range(0, 1)) = 1
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
		
		Fog {Mode Off}
		
        LOD 100
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }

            Blend One OneMinusSrcAlpha
			//Blend SrcAlpha One
            Cull Off
            ZWrite Off
			ColorMask RGB
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #pragma multi_compile_fwdbase

            uniform sampler2D _MainTex; 
            uniform float4 _MainTex_ST;

			uniform sampler2D _MainTex2;
			uniform float4 _MainTex2_ST;

            uniform float4 _TintColor;
			uniform float4 _TintColor2;

            uniform sampler2D _DisortTex; 
            uniform float4 _DisortTex_ST;

			uniform sampler2D _DisortTex2;
			uniform float4 _DisortTex2_ST;

            uniform float _DistortStrangth;
            uniform float _GLOW;
            uniform float _SpeedV;
            uniform float _SpeedU;

			uniform float _DistortStrangth2;
			uniform float _GLOW2;
			uniform float _SpeedV2;
			uniform float _SpeedU2;

			float _AlphaScale;

            struct VertexInput 
            {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            struct VertexOutput 
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            VertexOutput vert (VertexInput v) 
            {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.pos = UnityObjectToClipPos(v.vertex );
                return o;
            }

            fixed4 frag(VertexOutput i) : COLOR 
            {
                half t = _Time.y;
				half2 distortUV = (half2((_SpeedU*t),(_SpeedV*t))+i.uv0);
				half4 distortColor = tex2D(_DisortTex,TRANSFORM_TEX(distortUV, _DisortTex));
				half2 mainUV = ((distortColor.r*_DistortStrangth)+i.uv0);
				half4 color = tex2D(_MainTex,TRANSFORM_TEX(mainUV, _MainTex));
				half3 emissive = distortColor.rgb*color.rgb * _TintColor.rgb*_GLOW;
				half finalAlpha = distortColor.a * _TintColor.a * i.vertexColor.a;

				half2 distortUV2 = (half2((_SpeedU2*t), (_SpeedV2*t)) + i.uv0);
				half4 distortColor2 = tex2D(_DisortTex2, TRANSFORM_TEX(distortUV2, _DisortTex2));
				half2 mainUV2 = ((distortColor.r*_DistortStrangth2) + i.uv0);
				half4 color2 = tex2D(_MainTex2, TRANSFORM_TEX(mainUV2, _MainTex2));
				half3 emissive2 = (((2.0*distortColor2.rgb)*color2.rgb)*(color2.rgb*i.vertexColor.rgb*(_TintColor2.rgb*_GLOW2)*color2.a*i.vertexColor.a));

				half3 finalColor = emissive * finalAlpha + emissive2;

				#ifdef UNITY_UI_CLIP_RECT
				finalAlpha *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect);
				#endif

				finalAlpha *= _AlphaScale;
				return fixed4(finalColor, finalAlpha);
            }

            ENDCG
        }
    }

}
