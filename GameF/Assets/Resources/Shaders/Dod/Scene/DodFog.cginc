
#define DOD_FOG_COORDS(index) float2 fogCoord : TEXCOORD##index;
#define DOD_TRANSFER_FOG DodCalcFogCoord
#define DOD_APPLY_FOG DodApplyFog

uniform fixed4 _DODFogColor;
uniform float _DODDepthFogStart;
uniform float _DODDepthFogEnd;
uniform float _HeighFogStart;
uniform fixed4 _HightFogColor;
uniform float _HeighFogEnd;
uniform float _DODFogIntensity;

uniform float _SkyboxFogHeight;
uniform float _DODSkyboxFogIntensity;
uniform float3 _DODSunColor;


//计算雾
inline void DodCalcFogCoord(inout float2 fogCoord, float3 vertex)
{
	fogCoord = 0;
#if defined (DOD_FOG_NONE)
	return;
#endif

#if defined(FOG_SKY_BOX)
            fogCoord.y = vertex.y;
#else
	//深度雾
	float3 viewPos = UnityObjectToViewPos(vertex);
	float z = length(viewPos);
	float factor = 0;

	factor = (_DODDepthFogEnd - z) / (_DODDepthFogEnd - _DODDepthFogStart);

	fogCoord.x = saturate(factor);
	float3 worldPos = mul(unity_ObjectToWorld, vertex);
	fogCoord.y = worldPos.y;
#endif
}

//混合雾的颜色
inline void DodApplyFog(float2 fogCoord, float3 worldPos, inout fixed3 finalColor)
{
#if defined (DOD_FOG_NONE)
	return;
#endif
#if defined(LINEARCOLOR)
	_DODFogColor *= _DODFogColor;
#endif
	_HightFogColor*=_HightFogColor;
	float3 worldPosDir = normalize(worldPos);
	half3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	half3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

#if defined (FOG_SKY_BOX)
	#if defined(HIGHTFOG) || defined(DOD_SUN_ON)
		fixed3 hightfog = fixed3(0.0,0.0,0.0);
		fixed hightY = worldPos.y - _HeighFogStart;
		fogCoord.y -= _SkyboxFogHeight/5;
		half3 skyDownFog = lerp(_HightFogColor,finalColor,lerp(clamp((fogCoord.y+0.3),0.0,1.0),1.0,1-_DODSkyboxFogIntensity));
		half3 skyfog = lerp(skyDownFog,_DODFogColor, lerp(0.0,(1-smoothstep(0, _SkyboxFogHeight, fogCoord.y<=0.0?abs(fogCoord.y)*2:fogCoord.y)),_DODSkyboxFogIntensity));
		#if defined(DOD_SUN_ON)
		half vl = (dot(viewDir,-worldLightDir));
		skyfog = lerp(skyfog,finalColor,vl);
		#endif
		finalColor = skyfog;
	#endif
#elif defined(DOD_FOG_LINEAR)
	fixed3 fogColor = lerp(_DODFogColor, finalColor, fogCoord.x*fogCoord.x);
	fixed3 finalFog = fogColor;
	#if defined(HIGHTFOG)
		fixed3 hightfog = fixed3(0.0,0.0,0.0);
		fixed hightY = worldPos.y - _HeighFogStart;
		fixed hight = clamp((_HeighFogEnd-hightY)/hightY*1.65,0.0,1.0);
		hightfog = lerp(_HightFogColor,finalColor,fogCoord.x*fogCoord.x*fogCoord.x);
		finalFog = lerp(fogColor,hightfog,hight);
	#endif
#if defined(DOD_SUN_ON)
		half vl = clamp((dot(viewDir,-worldLightDir)),0.0,1.0);
		fixed3 sunfog = lerp((_DODSunColor + finalFog)*vl, finalColor, fogCoord.x*fogCoord.x);
		finalFog = lerp(finalFog,sunfog,smoothstep(0,1,vl));
#endif
	finalColor = finalFog;

#endif



}
