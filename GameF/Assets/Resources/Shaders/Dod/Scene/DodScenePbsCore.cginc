#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "DodFog.cginc"
#include "AutoLight.cginc"
#define PI 3.1415926535897932384626433832795
#define Dod_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04)
#define Dod_ShadowRange 0.35
half3 G2L(half3 value){
#if defined(LINEARCOLOR)
	return value * value;
#else
	return value;
#endif
}

half3 L2G(half3 value){
#if defined(LINEARCOLOR)
	return pow(value,half3(0.5,0.5,0.5));
#else
	return value;
#endif
}

half3 G2Lsrgb(half3 srgb)
{
#if defined(LINEARCOLOR)	
	return srgb * (srgb * (srgb * 0.305306011 + 0.682171111) + 0.012522878);
#else
	return srgb;
#endif
}

half clipMatrix(half2 pos, half alpha) {
    pos *= _ScreenParams.xy;
	half Thresholds[16] =
	{
		1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
		13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
		4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
		16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
	};
	int index = int(fmod(pos.x,4)) + int(fmod(pos.y,4)) * 4;
    return alpha - Thresholds[index];
}

void doClip(float2 pos, float alpha) {
    clip(clipMatrix(pos, alpha));
}

struct Scenea2v
{
    float4 vertex : POSITION;
	float3 normal : NORMAL;
    float2 texcoord : TEXCOORD0;
	float2 texcoord2 : TEXCOORD1;
	fixed4 color : COLOR;
#if defined(NORMAL_ON)
	float4 tangent   : TANGENT;
#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Scenev2f
{
	float4 pos : SV_POSITION;
	float3 worldNormal : TEXCOORD0;
	float3 worldPos : TEXCOORD1;
    float2 uv : TEXCOORD2;
	DOD_FOG_COORDS(3)
#ifdef LIGHTMAP_ON
	float2 uvLM : TEXCOORD4;
#endif
	float3 viewDir : TEXCOORD5;
#if defined(SHADOW_ON)
	SHADOW_COORDS(13)	
#endif
#if defined(NORMAL_ON)
	float3 tangent   : TEXCOORD6;
	float3 binormal : TEXCOORD7;
#endif
#if defined(TERRAIN)
	float2 tc_Control : TEXCOORD8;
	float2 tc_Splat0 : TEXCOORD9;
	float2 tc_Splat1 : TEXCOORD10;
	float2 tc_Splat2 : TEXCOORD11;
	float2 tc_Splat3 : TEXCOORD12;
#endif
#if defined(FADE_ON)
	float4 scrpos : TEXCOORD14;
#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

sampler2D _MainTex;
sampler2D _NormalTex;
sampler2D _MaskTex;
float4 _MainTex_ST;
float _Metallic;
float _roughness;
float _Emission;
half4 _EmissionColor;
float4 _MainColor;
#if defined(TERRAIN)
sampler2D _Splat0;
sampler2D _Splat1;
sampler2D _Splat2;
sampler2D _Splat3;
sampler2D _Control;
float4 _Splat0_ST,_Splat1_ST,_Splat2_ST,_Splat3_ST,_Control_ST;
#endif
#if defined(CUTOFF)
half _Cutoff;
#endif
#if defined(FADE_ON)
half _startTime;
#endif
float FadeShadows (float3 wordposi, float attenuation) {
    #if HANDLE_SHADOWS_BLENDING_IN_GI
        float viewZ =dot(_WorldSpaceCameraPos - wordposi, UNITY_MATRIX_V[2].xyz);
        float shadowFadeDistance =UnityComputeShadowFadeDistance(wordposi, viewZ);
        float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
        attenuation = saturate(shadowFade+attenuation);
    #endif
    return attenuation;
}

half OneMinusReflectivityFromMetallicDod(fixed metallic)
{
    fixed oneMinusDielectricSpecDod = Dod_ColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpecDod - metallic * oneMinusDielectricSpecDod;
}

Scenev2f SceneVert (Scenea2v v)
{
    Scenev2f o;
	UNITY_INITIALIZE_OUTPUT(Scenev2f,o);
	UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldNormal = UnityObjectToWorldNormal(v.normal);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.worldPos);
    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
#if defined(FADE_ON)
	o.scrpos = ComputeScreenPos(o.pos);
#endif
#if defined(NORMAL_ON)
	half4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	float3x3 tangentToWorld = CreateTangentToWorldPerVertex(o.worldNormal, tangentWorld.xyz, tangentWorld.w);
	o.tangent = tangentToWorld[0];
	o.binormal = tangentToWorld[1];
#endif
#ifdef LIGHTMAP_ON
	o.uvLM = v.texcoord2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
#if defined(TERRAIN)
	o.tc_Control = TRANSFORM_TEX(v.texcoord, _Control);
	o.tc_Splat0 = TRANSFORM_TEX(v.texcoord,_Splat0);
	o.tc_Splat1 = TRANSFORM_TEX(v.texcoord,_Splat1);
	o.tc_Splat2 = TRANSFORM_TEX(v.texcoord,_Splat2);
	o.tc_Splat3 = TRANSFORM_TEX(v.texcoord,_Splat3);
#endif
#if defined(SHADOW_ON)
	TRANSFER_SHADOW(o);
#endif
	DOD_TRANSFER_FOG(o.fogCoord, v.vertex);
    return o;
}


half3 DiffuseAndSpecularFromMetallicDod (half3 albedo, float metallic , out half3 specColor)
{
    specColor = lerp(Dod_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    fixed oneMinusReflectivityDod = OneMinusReflectivityFromMetallicDod(metallic);
    return albedo * oneMinusReflectivityDod;
}

float SmithJointGGXVisibilityTermDod (float NdotL, float NdotV, float roughness)
{
    float a = roughness;
//	half k = (a*a)/8.0;
    float lambdaV = NdotL * (NdotV * (1.0 - a) + a);
    float lambdaL = NdotV * (NdotL * (1.0 - a) + a);

    return min(0.5 / (lambdaV + lambdaL + 1e-5), 128.0);
}

float GGXTermNotN (float NdotH, float roughness)
{
    float a2 = roughness * roughness;
    float d = (NdotH * a2 - NdotH) * NdotH + 1.0; 
    return min(a2 / (d * d + 1e-5), 128.0);
}

float3 FresnelTermCustom (float3 F0, float cosA)
{
    float t = Pow5 (1.0 - cosA);   
    return F0 + (float3(1.0,1.0,1.0)-F0) * t;
}

float3 SpecularBRDF(float ndl, float ndv, float ndh, float ldh, float roughness, float3 specular_color)
{
    float roughness2 = roughness * roughness;
    float visTerm = SmithJointGGXVisibilityTermDod( ndl, ndv, roughness2 );
    float normTerm = GGXTermNotN(ndh, roughness2);
    return visTerm * normTerm * FresnelTermCustom(specular_color, ldh);
}


half3 pbrLightmapTmp(half3 finalcolor)
{
	half3 colorT = half3(0.0,0.0,0.0);
#if defined(DOD_PLATFORM_PC)
	colorT = finalcolor/(half3(0.78,0.78,0.78)+finalcolor)*1.165;
#elif defined(DOD_PLATFORM_MOBILE) 
	return L2G(finalcolor);
#endif
	return colorT;
}


half3 DodDecodeHDR (half4 data, bool useAlpha, half scale)
{
	half alpha = useAlpha ? data.a : 1.0;
	return (scale * alpha) * data.rgb;
}

half3 GetReflectIndirect(half3 worldRefl, half roughness)
{	
	half mip = roughness * UNITY_SPECCUBE_LOD_STEPS;

	half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, worldRefl, mip);
	half3 specular = DodDecodeHDR(rgbm, unity_SpecCube0_HDR.w == 1, unity_SpecCube0_HDR.x);
	return specular * (1-roughness);
}

half3 GrassLight(half3 lightmapColor, half3 baseColor,half3 worldNormal,half shadow)
{
	half3 finalColor = half3(0.0,0.0,0.0);
	baseColor =G2L( baseColor);
	lightmapColor.rgb =clamp( (lightmapColor.rgb),half3(0.287,0.287,0.287),half3(0.55,0.55,0.55));
	half3 diffuse = (clamp(shadow+0.135 ,0.1,1.0)) * baseColor;
	diffuse = baseColor *(clamp(shadow+0.335 ,0.0,1.0));
	return  diffuse;
}

//half3 GetLightmapIndirect(half3 indrect)
//{
//	#if defined (UNITY_HARDWARE_TIER3) || defined (UNITY_HARDWARE_TIER2)
//		return clamp(G2Lsrgb(indrect),fixed3(0.28,0.28,0.28),fixed3(3.0,3.0,3.0));
//	#elif defined (UNITY_HARDWARE_TIER1)
//		return indrect;
//	#endif
//}

half3 PbrLight(float3 worldPos, half3 lightDir,half4 LightmapDir, half3 viewDir, half3 normalDir, half3 baseColor, half3 PbrMask)
{
	half3 finalColor = half3(0.0,0.0,0.0);

	half roughness = PbrMask.b;
	half metallic = PbrMask.r;
	baseColor = G2L(baseColor);

	half3 specularColor = half3(1.0,1.0,1.0);
	//lightmap baseColor
	baseColor = DiffuseAndSpecularFromMetallicDod(baseColor,metallic,specularColor);
	half ndv = abs(dot(normalDir,viewDir));
	half3 viewReflectDir = reflect(-viewDir,normalDir);
	half3 halfDir = normalize(viewDir + lightDir);
	half ndh = clamp(dot(normalDir,halfDir),0.0,1.0);
	half ldh =clamp(dot(lightDir,halfDir),0.0,1.0);
	half nl =clamp(dot(lightDir,normalDir),0.0,1.0);
	LightmapDir.rgb = G2L(LightmapDir.rgb);

	half3 diffuse = baseColor * nl * LightmapDir.a*_LightColor0*2.0 + lerp( baseColor * LightmapDir,baseColor*LightmapDir*LightmapDir.a,Dod_ShadowRange);
	//SPECULAR
	half3 directSpecular = half3(0.0,0.0,0.0);

	directSpecular =  SpecularBRDF(max(0.0,dot(normalDir,lightDir)), ndv, ndh, ldh, roughness, specularColor) * LightmapDir.a;	
	half3 reflectColor = GetReflectIndirect(viewReflectDir,roughness)*PbrMask.b;
	half3 specular =directSpecular;	
	finalColor = diffuse + specular + reflectColor;
	return finalColor;
}

half3 PbrTerrainLight(float3 worldPos, half3 lightDir,half4 LightmapDir, half3 viewDir, half3 normalDir, half3 baseColor, half3 PbrMask)
{
	half3 finalColor = half3(0.0,0.0,0.0);

	half roughness = PbrMask.b;
	half metallic = PbrMask.r;
	baseColor = G2L(baseColor);
	half3 specularColor = half3(1.0,1.0,1.0);
	//lightmap baseColor
	baseColor = DiffuseAndSpecularFromMetallicDod(baseColor,metallic,specularColor);
	half ndv = abs(dot(normalDir,viewDir));
	half3 halfDir = normalize(viewDir + lightDir);
	half ndh = clamp(dot(normalDir,halfDir),0.0,1.0);
	half ldh =clamp(dot(lightDir,halfDir),0.0,1.0);
	half nl =clamp(dot(lightDir,normalDir),0.0,1.0);
	LightmapDir.rgb = G2L(LightmapDir.rgb);
	half3 diffuse;
	diffuse = baseColor * nl * LightmapDir.a*_LightColor0*2.0 + lerp( baseColor * LightmapDir,baseColor*LightmapDir*LightmapDir.a,Dod_ShadowRange);
	//SPECULAR
	half3 directSpecular = half3(0.0,0.0,0.0);
	directSpecular =  SpecularBRDF(max(0.0,dot(normalDir,lightDir)), ndv, ndh, ldh, roughness, specularColor) * LightmapDir.a;
	half3 specular =clamp( directSpecular,0.0,1.0);	
	finalColor = diffuse + specular;
	return finalColor;
}

half3 simpleLight(half3 LightmapDir, half3 baseColor, half shadow)
{
	half3 finalColor = half3(0.0,0.0,0.0);
	baseColor = G2L(baseColor);
	LightmapDir.rgb = G2L(LightmapDir.rgb);	
	half3 diffuse;
	diffuse = baseColor * shadow * _LightColor0 + baseColor*LightmapDir * 0.8;//trick为了弥补和高配线性计算的色差
	finalColor = diffuse;
	return finalColor;
}

half3 simpleLight(half3 LightmapDir, half3 baseColor, half shadow, fixed nl)
{
	shadow = clamp(shadow,0.1,1.0);
	half3 finalColor = half3(0.0,0.0,0.0);
	baseColor = G2L(baseColor);	
	LightmapDir.rgb = G2L(LightmapDir.rgb);
	half3 diffuse;
#if defined(LINEARCOLOR)
	diffuse = baseColor * shadow * _LightColor0*2.0 * nl + lerp( baseColor * LightmapDir,baseColor*LightmapDir*shadow,Dod_ShadowRange);
#else
	diffuse = baseColor * shadow * _LightColor0 * nl + baseColor*LightmapDir * 0.9;//trick为了弥补和高配线性计算的色差
#endif
	finalColor =diffuse;
	return finalColor;
}

fixed4 SceneFrag (Scenev2f i) : SV_Target
{
	half4 col = tex2D(_MainTex, i.uv);
	half3 worldPos = normalize(i.worldPos);
	  col *= _MainColor;
#if defined(CUTOFF)
	clip(col.a - _Cutoff);
#endif
#if defined(TRANSPARENT)
  col.a = col.a * _MainColor.a;

#endif
	half4 mask = tex2D(_MaskTex,i.uv);
#if defined(MIDLIGHT_ON) || defined(PRSLIGHT_ON)
	half3 worldNormal = normalize(i.worldNormal);				
	half3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	half3 ndl = max(0.0,dot(worldNormal,worldLightDir));               
	half3 viewDir = normalize(i.viewDir);
#endif
#if defined(NORMAL_ON) 			
	float3x3 tangentTransform = float3x3(i.tangent, i.binormal, worldNormal);
	half3 normalLocal = UnpackNormal(tex2D(_NormalTex, i.uv));
	half3 normalMapDir = normalize(mul(normalLocal, tangentTransform));
#endif			
#if defined(TERRAIN)
	fixed4 splat_control = tex2D (_Control, i.tc_Control).rgba;		
	fixed3 lay1 = tex2D (_Splat0, i.tc_Splat0);
	fixed3 lay2 = tex2D (_Splat1, i.tc_Splat1);
	fixed3 lay3 = tex2D (_Splat2, i.tc_Splat2);
	fixed3 lay4 = tex2D (_Splat3, i.tc_Splat3);
	col.rgb = (lay1 * splat_control.r + lay2 * splat_control.g + lay3 * splat_control.b + lay4 * splat_control.a);
#endif
#ifdef LIGHTMAP_ON
	half4 lm ;
	half4 indirectColor;
	indirectColor = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uvLM);
	lm = indirectColor * 2.0;
	fixed backatten = UnitySampleBakedOcclusion(i.uvLM,worldPos);
	lm.a = backatten;
	half4 maskRGBA = mask;
	half3 emiss = mask.g*_EmissionColor * _Emission+half3(1.0,1.0,1.0);
#if defined(PRSLIGHT_ON)
	maskRGBA.r=mask.r*_Metallic;
	maskRGBA.b=mask.a*(1-_roughness);
	col.rgb = PbrLight(worldPos,worldLightDir,lm,viewDir,normalMapDir,col.rgb,maskRGBA.rgb);
#elif defined(MIDLIGHT_ON)
	col.rgb = simpleLight(lm.rgb,col.rgb,backatten,ndl);
#elif defined(SIMPLELIGHT_ON)
	col.rgb = simpleLight(lm.rgb,col.rgb,backatten);
#endif
	col.rgb *= emiss;
#endif
	fixed4 finalColor = col;
#if defined(SHADOW_ON)
	fixed shadow = SHADOW_ATTENUATION(i);
	shadow = FadeShadows(i.worldPos,shadow);
	shadow = clamp(shadow,0.5,1.0);
	finalColor *= shadow;
#endif
	DOD_APPLY_FOG(i.fogCoord, i.worldPos, finalColor.rgb);
#ifdef LIGHTMAP_ON
	finalColor.rgb = pbrLightmapTmp(finalColor.rgb);				
#endif
#if defined(FADE_ON)
	float2 screenpos = i.scrpos.xy/i.scrpos.w;
	doClip(screenpos,_startTime);
#endif
				
    return finalColor;
}