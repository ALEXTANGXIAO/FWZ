#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "DodFog.cginc"
#include "AutoLight.cginc"
float clipMatrix(float2 pos, float alpha) {
    pos *= _ScreenParams.xy;
    float Thresholds[16] =
    {
        1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
        13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
        4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
        16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
    };
	int index = int(fmod(pos.x,4)) + int(fmod(pos.y,4)) * 4 ;
    return alpha - Thresholds[index];
}
void doClip(float2 pos, float alpha) {
    clip(clipMatrix(pos, alpha));
}
struct a2v
{
    float4 vertex    : POSITION;  
	float3 normal    : NORMAL;
    float2 texcoord  : TEXCOORD0;
	float2 texcoord2 : TEXCOORD1;
	fixed4 color     : COLOR;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
	float4 pos         : SV_POSITION;
	float3 worldNormal : TEXCOORD0;
	float3 worldPos    : TEXCOORD1;
    float2 uv          : TEXCOORD2;
	DOD_FOG_COORDS(3)
#ifdef LIGHTMAP_ON
	float2 uvLM : TEXCOORD4;
#endif		
#if defined(FADE_ON)
	float4 scrpos : TEXCOORD14;
#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

sampler2D _MainTex;
float4 _MainTex_ST;
half  _Cutoff, _LightmapScale;
half4 _MainColor;
half4 _Direction;
half _TimeScale, _TimeDelay;
half _startTime;

v2f Naturevert (a2v v)
{
    v2f o;
	UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);

#ifdef SWING_ON
	half dis      = distance(v.vertex, half4(0, 0, 0, 0)) * v.color.b;  
	half time     = (_Time.y + _TimeDelay) * _TimeScale;
	v.vertex.xyz += dis * (sin(time) * cos(time * 2 / 3) + 1) * _Direction.xyz;
#endif
	o.pos		  = UnityObjectToClipPos(v.vertex);
	o.worldNormal = UnityObjectToWorldNormal(v.normal);
	o.worldPos	  = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.uv       	  = TRANSFORM_TEX(v.texcoord, _MainTex);

#ifdef LIGHTMAP_ON
	o.uvLM = v.texcoord2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif	
#if defined(FADE_ON)
	o.scrpos = ComputeScreenPos(o.pos);
#endif
	DOD_TRANSFER_FOG(o.fogCoord, v.vertex);
    return o;
}

fixed4 Naturefrag (v2f i) : SV_Target
{
	fixed4 col = tex2D(_MainTex, i.uv);
	clip(col.a - _Cutoff);
	fixed3 worldNormal   = normalize(i.worldNormal);
	fixed3 worldPos      = normalize(i.worldPos);
	fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
	half Ndl = max(0, dot(worldNormal, worldLightDir) * 0.6 + 0.4); 
	half4 indirectColor;				
#ifdef LIGHTMAP_ON
	indirectColor = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uvLM);
	half4 lm = indirectColor*4.0;
#if defined(LINEARCOLOR)
	col.rgb *= col.rgb;
	lm.rgb *=lm.rgb;
#endif
	fixed backatten = UnitySampleBakedOcclusion(i.uvLM,i.worldPos);	
	col.rgb = (clamp(backatten ,0.2,1.0)) * col.rgb * lm.rgb + _LightColor0.rgb*col.rgb*Ndl;
	col.rgb *= _MainColor;
#else
	col.rgb = _LightColor0.rgb * col.rgb * Ndl;
#endif
	fixed4 finalColor = col;
	finalColor.a      = col.a;
	DOD_APPLY_FOG(i.fogCoord, i.worldPos, finalColor.rgb);
#if defined(LINEARCOLOR)
	finalColor = pow(finalColor,0.5);
#endif
#if defined(FADE_ON)
	float2 screenpos = i.scrpos.xy/i.scrpos.w;
	doClip(screenpos,_startTime);
#endif
    return finalColor;
}