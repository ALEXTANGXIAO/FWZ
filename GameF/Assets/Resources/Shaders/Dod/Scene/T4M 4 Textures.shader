Shader "T4MShaders/ShaderModel2/Diffuse/T4M 4 Textures" {
Properties {
	_Splat0 ("Layer 1", 2D) = "white" {}
	_Splat1 ("Layer 2", 2D) = "white" {}
	_Splat2 ("Layer 3", 2D) = "white" {}
	_Splat3 ("Layer 4", 2D) = "white" {}
	_Control ("Control (RGBA)", 2D) = "white" {}
	_MainTex ("Never Used", 2D) = "white" {}
}
      
SubShader {
	Tags {
   "SplatCount" = "4"
   "RenderType" = "Opaque"
	}
CGPROGRAM
#pragma surface surf Lambert vertex:vert finalcolor:FinalColor
#pragma exclude_renderers xbox360 ps3
#pragma multi_compile DOD_FOG_NONE DOD_FOG_LINEAR DOD_FOG_EXP DOD_FOG_EXP2
#pragma target 3.0

#include "CustomFog.cginc"
struct Input {
	float2 tc_Control : TEXCOORD0;
	float2 tc_Splat0 : TEXCOORD1;
	float2 tc_Splat1 : TEXCOORD2;
	float2 tc_Splat2 : TEXCOORD3;
	float2 tc_Splat3 : TEXCOORD4;
	CUSTOM_FOG_COORDS(5)
	float3 worldPos : TEXCOORD6;
};
 
sampler2D _Control;
float4 _Control_ST;
sampler2D _Splat0,_Splat1,_Splat2,_Splat3;
float4 _Splat0_ST,_Splat1_ST,_Splat2_ST,_Splat3_ST;

void vert(inout appdata_full v, out Input data)
{
	UNITY_INITIALIZE_OUTPUT(Input, data);
	data.tc_Control.xy = TRANSFORM_TEX(v.texcoord, _Control);
	data.tc_Splat0 = TRANSFORM_TEX(v.texcoord, _Splat0);
	data.tc_Splat1 = TRANSFORM_TEX(v.texcoord, _Splat1);
	data.tc_Splat2 = TRANSFORM_TEX(v.texcoord, _Splat2);
	data.tc_Splat3 = TRANSFORM_TEX(v.texcoord, _Splat3);
	data.worldPos = mul(unity_ObjectToWorld, v.vertex);
	CUSTOM_TRANSFER_FOG(data.fogCoord, v.vertex);

}

void FinalColor(Input IN, SurfaceOutput o, inout fixed4 color)
{
	CUSTOM_APPLY_FOG(IN.fogCoord, IN.worldPos, color.rgb);
}
 
void surf (Input IN, inout SurfaceOutput o) {
	fixed4 splat_control = tex2D (_Control, IN.tc_Control).rgba;
		
	fixed3 lay1 = tex2D (_Splat0, IN.tc_Splat0);
	fixed3 lay2 = tex2D (_Splat1, IN.tc_Splat1);
	fixed3 lay3 = tex2D (_Splat2, IN.tc_Splat2);
	fixed3 lay4 = tex2D (_Splat3, IN.tc_Splat3);

	o.Alpha = 0.0;
	o.Albedo.rgb = (lay1 * splat_control.r + lay2 * splat_control.g + lay3 * splat_control.b + lay4 * splat_control.a);
}
ENDCG 
}
// Fallback to Diffuse
Fallback "Diffuse"
}
