// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// - Unlit
// - Scroll 2 layers /w Multiplicative op

Shader "Dodjoy/Scene/Scene_Sky_Scroll_Layer" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_ScrollX ("Base layer Scroll speed X", Float) = 1.0
	_ScrollY ("Base layer Scroll speed Y", Float) = 0.0
}

SubShader {
	Tags { "Queue"="Transparent" "RenderType"="Transparent" }
	
	Lighting Off Fog { Mode Off }
	
	ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha
			
	CGINCLUDE
	
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	fixed4 _Color;
	
	float4 _MainTex_ST;
	
	float _ScrollX;
	float _ScrollY;
	float _AMultiplier;
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};
		
	v2f vert (appdata_full v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord.xy,_MainTex) + frac(float2(_ScrollX, _ScrollY) * _Time);
		
		return o;
	}
	ENDCG


	Pass {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest		
		fixed4 frag (v2f i) : COLOR
		{
			fixed4 o;
			fixed4 tex = tex2D (_MainTex, i.uv);			
			o = tex * _Color;
			
			return o;
		}
		ENDCG 
	}	
}
}
