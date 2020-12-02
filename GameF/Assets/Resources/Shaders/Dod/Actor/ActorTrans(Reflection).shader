Shader "Dodjoy/Actor/ActorTrans(Reflection)"
{
    Properties
    {
        _Color("Color Tint", Color) = (1,1,1,1)
        _Alpha("Transparency", Range(0, 1)) = 1
        _Gloss("Gloss", Range(8, 128)) = 8
        _SpecScale("Specular Intensity", Float) = 1

        _RimRange("Rim Range", Float) = 1
        _RimScale("Rim Intensity", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"= "Transparent" "IgnorProjector" = "true"}

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 wPos : TEXCOORD1;
                float3 wNormal : TEXCOORD2;
            };


            half4 _Color;
            half _Alpha;
            float _Gloss;
            float _SpecScale;

            half3 _RimColor;
            float _RimRange;
            float _RimScale;

            inline half3 DodDecodeHDR (half4 data, bool useAlpha, half scale)
            {
                half alpha = useAlpha ? data.a : 1.0;
                return (scale * alpha) * data.rgb;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.wNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 lightDir = normalize(UnityWorldSpaceLightDir(i.wPos));
                half3 normalDir = normalize(i.wNormal);
                half3 viewDir = normalize( UnityWorldSpaceViewDir(i.wPos));
                half3 halfDir = normalize(lightDir + viewDir);
                half3 reflDir = normalize(reflect(-viewDir, normalDir));

                half NdotL = saturate(dot(normalDir, lightDir)); 
                half NdotH = saturate(dot(normalDir, halfDir));
                half NdotV = saturate(dot(normalDir, viewDir));

                //Diffuse
                half3 diffuse = (NdotL * 0.5 + 0.5) * _Color.rgb;
                //Specular
                half3 specular = pow(NdotH, _Gloss) * _SpecScale;
                //Reflection
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, 0.8);
                half3 reflColor = DodDecodeHDR(rgbm, unity_SpecCube0_HDR.w == 1, unity_SpecCube0_HDR.x);
                //Rim
                half rim = pow(1 - NdotV, _RimRange) * _RimScale;
                half3 rimColor = half3(rim, rim, rim);
                //final
                half3 finalColor = diffuse + specular + rimColor + reflColor;

                return half4(finalColor, _Alpha);
            }
            ENDCG
        }
    }
}
