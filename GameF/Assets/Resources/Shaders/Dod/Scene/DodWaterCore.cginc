#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "DodFog.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
	float4 color : COLOR;
	float3 normal : NORMAL;
};

struct v2f
{
	float4 pos : SV_POSITION;
	float4 screenPos : TEXCOORD0;
	float4 bumpCoords : TEXCOORD1;
	float4 worldPos : TEXCOORD2;
	float3 worldNormal : TEXCOORD3;
	DOD_FOG_COORDS(4)
};

fixed4 _Color;
fixed4 _DepthColor;
			

sampler2D _WaveTex;
float _WaveScale;
float4 _WaveDireciotn;
float4 _WaveTiling;

sampler2D _ReflectionTex;
sampler2D _RefractionTex;
float _RefractionOffset;

float _SpecScale;
float _Gloss;

float _Depth;
float _FresnelDepth;

float3 PerPixelNormal(sampler2D bumpMap, float4 coords, float bumpStrength)
{
	float2 bump = UnpackNormal(tex2D(bumpMap, coords.xy));
	bump += UnpackNormal(tex2D(bumpMap, coords.xy * 2));
	bump += UnpackNormal(tex2D(bumpMap, coords.xy * 8));
 
	float3 worldNormal = float3(0,0,0);
	worldNormal.xz = bump.xy * bumpStrength;
	worldNormal.y = 1;
	return worldNormal;
}

half FastFresnel(float3 I, float3 N, float R0)
{
	float icosIN = saturate(1 - dot(I, N));
	float i2 = icosIN * icosIN;
	float i4 = i2 * i2;
	return R0 + (1 - R0) * (i4 * icosIN);
}

v2f Watervert (appdata v)
{
    v2f o;	
	UNITY_INITIALIZE_OUTPUT(v2f,o);
    o.pos = UnityObjectToClipPos(v.vertex);
	o.screenPos = ComputeScreenPos(o.pos);
	o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.worldPos.w = v.color.r;
	//法线uv动画
#if defined(BUMPANIM_ON)
	o.bumpCoords = (o.worldPos.xzxz + _Time.yyyy * _WaveDireciotn.xyzw) * _WaveTiling.xyzw;
#elif defined(BUMPANIM_OFF)
	o.worldNormal = UnityObjectToWorldNormal(v.normal);
#endif
	DOD_TRANSFER_FOG(o.fogCoord, v.vertex);

    return o;
}

fixed4 Waterfrag (v2f i) : SV_Target
{
	float3 worldPos = i.worldPos;
	float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
    float3 viewDir = normalize(worldPos - _WorldSpaceCameraPos.xyz);
	float3 halfDir = normalize(-viewDir + lightDir);
#if defined(BUMPANIM_ON)
	half3 worldNormal = normalize(PerPixelNormal(_WaveTex,i.bumpCoords, _WaveScale));
#elif defined(BUMPANIM_OFF)
	half3 worldNormal = normalize(i.worldNormal);	
#endif
	float3 refrColor = half3(0.0,0.0,0.0);
#if defined(REFRACTION_ON)
	float depth = 1 - i.worldPos.w * _Depth;
	depth = depth / lerp(1, max(0.1, -viewDir.y), _FresnelDepth);
	
	//Reflraction
	float3 graColor = lerp(_Color, _DepthColor, depth);
	refrColor = lerp(graColor, _DepthColor, 0.5) * _Color.rgb;

	/*
	float2 offsets = worldNormal.xz * viewDir.y;
	float2 screenUV = i.screenPos.xy / i.screenPos.w + offsets * _RefractionOffset;
	refrColor = tex2D(_RefractionTex, screenUV).rgb;
	refrColor = lerp(refrColor, graColor, 0.5) * _Color.rgb;
	*/
#endif

	//Reflection
	half3 reflUV = reflect(-viewDir, worldNormal);
	float3 reflColor = tex2D(_ReflectionTex, reflUV);
	half fresnel = 1.0;
#if defined(FRESNEL_ON)				
	fresnel = FastFresnel(-viewDir, worldNormal, 0.02);
#endif
	//Specular
	half3 specColor = half3(0.0,0.0,0.0);
#if defined(SPEC_ON)
	half3 spec = pow(max(0, dot(halfDir, worldNormal)), _Gloss);
	specColor = spec * _LightColor0.rgb * _SpecScale * fresnel;
#endif
	fixed3 finalColor = reflColor * fresnel + refrColor * (1 - fresnel) + specColor;
	DOD_APPLY_FOG(i.fogCoord, worldPos, finalColor);
	return fixed4(finalColor, 0.8);
}