
struct Input {
	float2 uv_MainTex : TEXCOORD0;
};

///先放在这，需要扩展的时候，在同一改为自定义的接口
struct MySurfaceOutput {
	fixed3 Albedo;
	fixed3 Normal;
	fixed3 Emission;
	fixed Specular;
	fixed Gloss;
	fixed Alpha;
};

sampler2D _MainTex;	

#ifdef SPEC_ON
fixed _Shininess;
half _SpecScale;
#endif

#ifdef NORMAL_MAP_ON
sampler2D _BumpMap;
#endif


inline fixed4 UnityMyLambertLight (SurfaceOutput s, half3 viewDir, UnityLight light)
{
	fixed diff = max (0, dot (s.Normal, light.dir));
	
#ifdef SPEC_ON
	half3 h = normalize (light.dir + viewDir);	
	half nh = max (0, dot (s.Normal, h));
	half spec = pow (nh, s.Specular*128.0) * s.Gloss * _SpecScale;
#endif
	
	fixed4 c;
	
#ifdef SPEC_ON
	c.rgb = s.Albedo * light.color * diff + light.color * spec;
#else
	c.rgb = s.Albedo * light.color * diff;
#endif
	
	c.a = s.Alpha;
	return c;
}

inline fixed4 LightingMyLambert (SurfaceOutput s, half3 viewDir, UnityGI gi)
{
	fixed4 c;
	c = UnityMyLambertLight (s, viewDir, gi.light);

#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
	//c.rgb += s.Albedo * gi.indirect.diffuse;
#endif
	c.rgb += s.Albedo * gi.indirect.diffuse;
	
	return c;
}


inline half4 LightingMyLambert_Deferred (SurfaceOutput s, half3 viewDir, UnityGI gi, out half4 outGBuffer0, out half4 outGBuffer1, out half4 outGBuffer2)
{
	UnityStandardData data;
	data.diffuseColor	= s.Albedo;
	data.occlusion		= 1;		
	// PI factor come from StandardBDRF (UnityStandardBRDF.cginc:351 for explanation)
	data.specularColor	= s.Gloss * (1/UNITY_PI);
	data.smoothness		= s.Specular;
	data.normalWorld	= s.Normal;

	UnityStandardDataToGbuffer(data, outGBuffer0, outGBuffer1, outGBuffer2);

	half4 emission = half4(s.Emission, 1);
	
	#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
		emission.rgb += s.Albedo * gi.indirect.diffuse;
	#endif

	return emission;
}


inline UnityGI MyUnityGI_Base(UnityGIInput data, half occlusion, half3 normalWorld)
{
	UnityGI o_gi;
	ResetUnityGI(o_gi);
	
	// Base pass with Lightmap support is responsible for handling ShadowMask / blending here for performance reason
    #if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
        half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
        float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
        float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
        data.atten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
    #endif
	
	o_gi.light = data.light;
	o_gi.light.color *= data.atten;
		
	#if defined(LIGHTMAP_ON)
		// Baked lightmaps
		fixed4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lightmapUV.xy);
		half3 bakedColor = DecodeLightmap(bakedColorTex);

		o_gi.indirect.diffuse = bakedColor;
		
		#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                ResetUnityLight(o_gi.light);
                o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
        #endif
		
	#else
		#if UNITY_SHOULD_SAMPLE_SH
        o_gi.indirect.diffuse = ShadeSHPerPixel (normalWorld, data.ambient, data.worldPos);
		#endif
	#endif
	
	return o_gi;
}

inline void LightingMyLambert_GI (
	SurfaceOutput s,
	UnityGIInput data,
	inout UnityGI gi)
{
	//UnityGlobalIllumination
	gi = UnityGI_Base (data, 1.0, s.Normal);
}

void surf (Input IN, inout SurfaceOutput o) {

	#ifdef SPEC_ON
	fixed4 lay1 = tex2D (_MainTex, IN.uv_MainTex);
	#else
	fixed3 lay1 = tex2D (_MainTex, IN.uv_MainTex).rgb;
	#endif
	
	o.Alpha = 0.0;
	o.Albedo = lay1.rgb;
	
	#ifdef NORMAL_MAP_ON
	o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
	#endif
	
	#ifdef SPEC_ON
	o.Gloss = lay1.a;
	o.Specular = _Shininess;
	#endif
}
