
Shader "Dodjoy/Scene/SceneItemSSS"      //JianpingWang //自定义SSS效果  //只供场景特殊物件使用  //20200416 //0428  //0513
{
	Properties 
	{
		[Header(Base)]
		[NoScaleOffset]
		_MainTex ("Base (RGB)", 2D) = "gray" {}		
		_BumpScale("BumpScale", Range(0, 1)) = 1
		[NoScaleOffset]
		[NORMAL]_BumpMap ("Normal", 2D) = "bump" {}
		
		[Space(20)][Header(SSS)]
		_SubColor ("SSS Color(RBGA)", Color) = (1.0, 1.0, 1.0, 1.0)   //A通道控制整体亮度
		_ThicknessScale ("ThicknessScale", Range(1, 3)) = 1.5
		[NoScaleOffset]
		_Thickness ("ThicknessMask (RGB)", 2D) = "bump" {}		      //R通道为产生SSS效果区域蒙板图    //G通道为Thickness图    //B为粗糙图
		[NoScaleOffset]
		_MatCap ("MatCap (RGB)", 2D) = "white" {}		        	  //可带颜色     

		[Space(20)][Header(Others)]
		_SpecColora ("Specular Color(RBG)", Color) = (0.5, 0.5, 0.5, 1.0)   
		_Shininess ("Shininess", Range (0.03, 1)) = 0.078125		
	}  

	SubShader 
	{
		Tags { "RenderType"="Opaque" "IgnoreProjector" = "true"}   

		Cull Off

		Pass 
		{
			Tags { "LightMode"="ForwardBase" } 
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag 

			#pragma multi_compile LIGHTMAP_ON
			#pragma multi_compile_fwdbase
//			#pragma multi_compile SHADOWS_SHADOWMASK;  

			#define DOD_FOG_LINEAR
			#define DOD_PLATFORM_MOBILE

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"

//			#include "DodFog.cginc"
			#include "AutoLight.cginc"
			#include "DodScenePbsCore.cginc"


			sampler2D  _BumpMap, _Thickness, _MatCap;
//			float4 	_MainTex_ST;
			half _ThicknessScale, _BumpScale, _Shininess;
			fixed4 _SubColor, _SpecColora;
			


			struct appdata
			{
				float4 vertex 	 : POSITION;
				float2 texcoord  : TEXCOORD0;
				float2 texcoord2 : TEXCOORD1;
				float3 normal 	 : Normal;
				float4 tangent 	 : Tangent; 
			};

			struct v2f 
			{
				float4 pos  	: SV_POSITION;
				float2 uv 		: TEXCOORD0;
				float3 worldPos : TEXCOORD1;				
				float4 TtoW0 	: TEXCOORD2;
				float4 TtoW1 	: TEXCOORD3;
				float4 TtoW2 	: TEXCOORD4;				
				SHADOW_COORDS(5)
				DOD_FOG_COORDS(6)
				#ifdef LIGHTMAP_ON
					float2 uvLM : TEXCOORD7;					
				#endif
			};

		
			///////////////////////////////////////////////拟SSS 分级3  		
			inline half4 LightingTranslucent3 (half4 Talbedo, half3 SSStex, half Shininess, half3 Normal, half3 lightDir, half3 viewDir, half atten, half4 _SubColor, half4 _SpecColora,  half3 lm, sampler2D _MatCap)
			{	
				viewDir 	= normalize ( viewDir );
				lightDir 	= normalize ( lightDir );
				half Thickness = SSStex.g * _ThicknessScale;
				half3 transAlbedo2 = Talbedo.rgb * Thickness * _SubColor.rgb;

				//---------采用matcap  不使用cubemap
				half2 matUV = half2(0,0);
				matUV.x = dot(normalize(UNITY_MATRIX_IT_MV[0].xyz), Normal);
                matUV.y = dot(normalize(UNITY_MATRIX_IT_MV[1].xyz), Normal);
                matUV   = matUV * 0.5 + 0.5;
				half3 matCapTex = tex2D(_MatCap, half2(matUV.x, 1.0 - matUV.y)).rgb;
				//---------				
				half3 matCapColor  = Talbedo.rgb * matCapTex;
				
				half3 h 	= normalize (lightDir + viewDir);
				half  diff 	= max (0, dot (Normal, lightDir));
				half  nh 	= max (0, dot (Normal, h));
				half  spec 	= pow (nh, Shininess*128.0) * Talbedo.a * _SpecColora.rgb;
				half3 diffAlbedo =  Talbedo.rgb * lm  + (Talbedo.rgb * diff  + spec) * _LightColor0.rgb * atten;
				
				half4 c;
				c.rgb 	= diffAlbedo + (transAlbedo2 + matCapColor) * SSStex.r;
				c.rgb  *= _SubColor.a;  //备注：效果调整时如果非SSS区域太暗可放置上面相乘，只控制SSS区域的明暗调节
				c.a 	= 1;

				return c;
			}
			///////////////////////////////////////////////拟SSS 

			///////////////////////////////////////////////拟SSS 分级2  去掉matcap反射  去掉光滑
			inline half4 LightingTranslucent2 (half4 Talbedo, half3 SSStex, half3 Normal, half3 lightDir, half atten, half4 _SubColor, half3 lm)
			{					
				lightDir = normalize ( lightDir );
				half Thickness = SSStex.g * _ThicknessScale * SSStex.r;			
			
				half3 	transAlbedo2 = Talbedo.rgb * Thickness * _SubColor.rgb;
				
				half  diff 	= max (0, dot (Normal, lightDir));
				half3 diffAlbedo =  Talbedo.rgb * lm  + (Talbedo.rgb * diff) * _LightColor0.rgb * atten;			
				
				half4 c;
				c.rgb 	= transAlbedo2 + diffAlbedo;
				c.rgb  *= _SubColor.a;
				c.a 	= 1;

				return c;
			}
			///////////////////////////////////////////////拟SSS 

			v2f vert (appdata v) 
			{
				v2f o;

				o.uv 	= TRANSFORM_TEX(v.texcoord, _MainTex);
				#ifdef LIGHTMAP_ON
					o.uvLM = v.texcoord2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				o.pos 	   = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			
				fixed3 worldNormal   = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent  = UnityObjectToWorldDir(v.tangent.xyz);                                   
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;                

				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, o.worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, o.worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, o.worldPos.z);

				TRANSFER_SHADOW(o);
				DOD_TRANSFER_FOG(o.fogCoord, v.vertex);

				return o;
			}




			fixed4 frag (v2f i) : SV_Target  
			{
				half4 Albedo = tex2D(_MainTex, i.uv);
				half4 finiColor = Albedo;

					half3 viewDir  = UnityWorldSpaceViewDir(i.worldPos);
					half3 lightDir = _WorldSpaceLightPos0.xyz;				
					half3 bump     = normalize(UnpackNormal(tex2D(_BumpMap, i.uv)));
					bump.xy *= _BumpScale;
					bump.z   = sqrt(1.0 - saturate(dot(bump.xy , bump.xy)));
					bump     = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
								
					half3 SSStex   = tex2D(_Thickness, i.uv).rgb; 
					half4 Talbedo   = half4(G2L(Albedo.rgb), SSStex.b);													

				#ifdef LIGHTMAP_ON
					half3 lm = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uvLM);
					lm = lm * 2;     
					half backatten = UnitySampleBakedOcclusion(i.uvLM, i.worldPos);
					finiColor = LightingTranslucent2 (Talbedo, SSStex, bump, lightDir, backatten, _SubColor, lm);				
				#endif

				
				#ifdef LIGHTMAP_ON
					finiColor.rgb = pbrLightmapTmp(finiColor.rgb);	
				#endif
				
				DOD_APPLY_FOG(i.fogCoord, i.worldPos, finiColor.rgb);

				return finiColor;
			}
		ENDCG  
		}
	}Fallback "Dodjoy/FallBack"
    
}














