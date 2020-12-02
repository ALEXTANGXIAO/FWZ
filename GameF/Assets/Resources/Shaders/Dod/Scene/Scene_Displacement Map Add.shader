// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Dodjoy/Scene/Displacement Map Add" {
Properties {
	_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	_NoiseTex ("Distort Texture (RG)", 2D) = "white" {}
	_MainTex ("Alpha (A)", 2D) = "white" {}
	_HeatTime  ("Heat Time", range (-1,1)) = 0
	_ForceX  ("Strength X", range (0,1)) = 0.1
	_ForceY  ("Strength Y", range (0,1)) = 0.1

}

Category {
	Tags { "Queue"="Transparent" "RenderType"="Transparent" }
	Blend SrcAlpha One
	Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
	BindChannels {
		Bind "Color", color
		Bind "Vertex", vertex
		Bind "TexCoord", texcoord
	}

	SubShader 
	{
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile DOD_FOG_LINEAR
			//#pragma multi_compile_particles
			#include "UnityCG.cginc"
			#include "DodFog.cginc"

			struct appdata_t 
			{
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 texcoord: TEXCOORD0;
			};

			struct v2f 
			{
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 uvmain : TEXCOORD1;
				float3 wPos : TEXCOORD2;
				DOD_FOG_COORDS(3)
			};

			fixed4 _TintColor;
			fixed _ForceX;
			fixed _ForceY;
			fixed _HeatTime;
			float4 _MainTex_ST;
			float4 _NoiseTex_ST;
			sampler2D _NoiseTex;
			sampler2D _MainTex;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.uvmain = TRANSFORM_TEX( v.texcoord, _MainTex );
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				DOD_TRANSFER_FOG(o.fogCoord,v.vertex);
				return o;
			}

			fixed4 frag( v2f i ) : COLOR
			{
				//noise effect
				fixed4 offsetColor1 = tex2D(_NoiseTex, i.uvmain + _Time.xz*_HeatTime);
			    fixed4 offsetColor2 = tex2D(_NoiseTex, i.uvmain + _Time.yx*_HeatTime);
				i.uvmain.x += ((offsetColor1.r + offsetColor2.r) - 1) * _ForceX;
				i.uvmain.y += ((offsetColor1.r + offsetColor2.r) - 1) * _ForceY;

				fixed4 finalColor = (fixed4)1.0;
				fixed4 color = tex2D( _MainTex, i.uvmain);
				finalColor.rgb = 2.0f * i.color * _TintColor * color.rgb;
				finalColor.a = color.a;

				#if defined(DOD_FOG_LINEAR)
					DOD_APPLY_FOG(i.fogCoord, i.wPos, finalColor.rgb);
					finalColor.a *= saturate((i.fogCoord.x*i.fogCoord.x*i.fogCoord));
					finalColor.rgb *= finalColor.a;	
				#endif
				return finalColor;
			}
			ENDCG
		}
	}
	// ------------------------------------------------------------------
	// Fallback for older cards and Unity non-Pro
	
	SubShader {
		Blend DstColor Zero
		Pass {
			Name "BASE"
			SetTexture [_MainTex] {	combine texture }
		}
	}
}
}
