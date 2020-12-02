// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Dodjoy/Effect/Decals"
{
   Properties 
   {
	  _TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
      _MainTex ("Texture Image(RGBA)", 2D) = "black" {}
   }
   SubShader
   {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	LOD 100
	ZWrite Off
	//ZTest off
	//Blend SrcAlpha OneMinusSrcAlpha
	Blend SrcAlpha One
	ColorMask RGB
	Cull Off
	Lighting Off

      Pass 
      {   
		 Fog { Mode Off }
         CGPROGRAM
 
         #pragma vertex vert  
         #pragma fragment frag 
 
         // User-specified uniforms            
         uniform sampler2D _MainTex;   
		 uniform fixed4 _TintColor;
         uniform float fade;     
 
         struct vertexInput 
         {
            float4 vertex : POSITION;
            float4 tex : TEXCOORD0;
         };
         struct vertexOutput 
         {
            float4 pos : SV_POSITION;
            float4 tex : TEXCOORD0;
         };
 
         vertexOutput vert(vertexInput input) 
         {
            vertexOutput output;
 
            output.pos = UnityObjectToClipPos(input.vertex);
 
            output.tex = input.tex;

 
            return output;
         }
 
         float4 frag ( vertexOutput input ):Color
         {
            float4 rtc =  tex2D(_MainTex, float2(input.tex.xy));
            rtc.a *= fade;
            return 2.0f * _TintColor * rtc;
         }
 
         ENDCG
      }

   }
   FallBack "Diffuse"
}