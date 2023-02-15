#ifndef TOON_SHADING_INCLUDED
#define TOON_SHADING_INCLUDED


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Lexaria_common_functions.hlsl"

Texture2D _BaseMap, _NormalMap, _ShadowMask, _EmissionMap, _RimMask;
SamplerState sampler_BaseMap, sampler_NormalMap, sampler_ShadowMask, sampler_EmissionMap, sampler_RimMask;


Texture2D _MatCap1st, _MatCap1stMask, _MatCap2nd, _MatCap2ndMask;
SamplerState sampler_MatCap1st, sampler_MatCap1stMask, sampler_MatCap2nd, sampler_MatCap2ndMask;


TEXTURE2D(_CameraDepthTexture);
SamplerState sampler_CameraDepthTexture;

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float _BumpScale;

float _MatCap1stBlendWeight, _MatCap1stBlendMode, _MatCap1stMaskWeight;
float _MatCap2ndBlendWeight, _MatCap2ndBlendMode, _MatCap2ndMaskWeight;
float4 _MatCap1stTintColor, _MatCap2ndTintColor;

float4 _EmissionColor;
float4 _RimColor;
float _RimOffset, _RimThreshold, _RimMainStrength, _RimFresnelPower;


float _CelShadeMidPoint, _CelShadeSoftness;
float4 _LightTintColor, _ShadowTintColor, _BorderTintColor;
float _ReceiveShadowMappingAmount;
float _IsFace;
CBUFFER_END



struct Attributes
{
    float4 positionOS : POSITION;
    float2 uv: TEXCOORD0;
    float3 normalOS: NORMAL;
    float4 tangentOS: TANGENT;
    
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 positionWSAndFogFactor : TEXCOORD0;
    float2 uv: TEXCOORD1;
    float3 normalWS: TEXCOORD2;
    float3 tangentWS : TEXCOORD3;
    float3 bitangentWS : TEXCOORD4;
    float4 positionNDC : TEXCOORD5;
    float4 rimSamplePosVP : TEXCOORD6;
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord : TEXCOORD7;
    #endif
};

float4 ComputeRimScreenPos(float4 positionCS)
{
    float4 o = positionCS * 0.5f;
    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
    o.zw = positionCS.zw;
    return o / o.w;
}

Varyings ToonVert(Attributes input)
{
    Varyings output = (Varyings)0;
    const VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(input.positionOS);
    const VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.positionCS = vertex_position_inputs.positionCS;
    output.positionWSAndFogFactor.xyz = vertex_position_inputs.positionWS;
    output.positionWSAndFogFactor.w = ComputeFogFactor(vertex_position_inputs.positionCS.z);
	output.positionNDC = vertex_position_inputs.positionNDC;
    
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

    output.normalWS = float3(vertex_normal_inputs.normalWS);
    output.tangentWS = float3(vertex_normal_inputs.tangentWS);
    output.bitangentWS = float3(vertex_normal_inputs.bitangentWS);

    float3 normalVS = TransformWorldToViewDir(vertex_normal_inputs.normalWS, true);
    float3 positionVS = vertex_position_inputs.positionVS;
    float3 rimSamplePosVS = float3(positionVS.xy + normalVS.xy * _RimOffset, positionVS.z);
    float4 rimSamplePosCS = TransformWViewToHClip(rimSamplePosVS);
    output.rimSamplePosVP = ComputeRimScreenPos(rimSamplePosCS);
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertex_position_inputs);
    #endif
    return output;
}


half3 ApplyFog(half3 color, Varyings input)
{
    half fogFactor = input.positionWSAndFogFactor.w;
    color = MixFog(color, fogFactor);
    return color;
}


half4 ToonFrag(Varyings input) : SV_Target
{
    float4 shadowCoord = float4(0, 0, 0, 0);
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
        shadowCoord = TransformWorldToShadowCoord(input.positionWSAndFogFactor.xyz);
    #endif
    Light mainLight = GetMainLight(shadowCoord);
    float3 lightDir = normalize(mainLight.direction);
    float attenuation = mainLight.shadowAttenuation;

    // Additional Light
    // float attenuation = addLight.shadowAttenuation * addLight.distanceAttenuation;

    float3 lightColor = mainLight.color;
    float3 lightColorWithAttenuation = attenuation * lightColor;
    
    float4 finalColor = float4(0, 0, 0, 0);

    
    float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
    #ifdef _ENABLE_SHADOWMASK
    float4 var_ShadowMask = SAMPLE_TEXTURE2D(_ShadowMask, sampler_ShadowMask, input.uv);
    #endif
    float4 var_EmissionMap = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv);
    float var_RimMask = SAMPLE_TEXTURE2D(_RimMask, sampler_RimMask, input.uv).r;
    



    float3 normalWS;
    #ifdef _ENABLE_NORMALMAP
        float3 var_normalmap = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv), _BumpScale);
        normalWS = TransformTangentToWorld(var_normalmap, float3x3(input.tangentWS, input.bitangentWS, input.normalWS));
    #else
        normalWS = input.normalWS;
    #endif
        normalWS = NormalizeNormalPerPixel(normalWS);

    float3 normalVS = TransformWorldToViewDir(normalWS, true);
    float3 viewDirWS = normalize(GetCameraPositionWS() - input.positionWSAndFogFactor.xyz);
    float3 viewDirVS = TransformWorldToViewDir(viewDirWS, true);
    float2 matcapUV = cross(normalVS, viewDirVS).xy;
    matcapUV = float2(-matcapUV.y, matcapUV.x) * 0.5 + 0.5;
    float NdotL = dot(normalWS, lightDir);
    float half_lambert = pow(NdotL * 0.5 + 0.5, 2);


    // Rim Light
    float depth = input.positionNDC.z / input.positionNDC.w;
    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
    float rimOffsetDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, input.rimSamplePosVP).r;
    float linearEyerimOffsetDepth = LinearEyeDepth(rimOffsetDepth, _ZBufferParams);
    float depthDiff = linearEyerimOffsetDepth - linearEyeDepth;
    float rimRatio = 1 - saturate(dot(viewDirWS, normalWS));
    rimRatio = pow(rimRatio, _RimFresnelPower);
    float rimIntensity = step(_RimThreshold, depthDiff) * var_RimMask;
    rimIntensity = lerp(0, rimIntensity, rimRatio);
    float4 rimColor = lerp(_RimColor, _RimColor * var_BaseMap, _RimMainStrength);
    rimColor.rgb *= rimIntensity * lightColorWithAttenuation;
    finalColor.rgb += rimColor.rgb;


    // Cel Shade
    float litOrShadowArea = smoothstep(_CelShadeMidPoint - _CelShadeSoftness, _CelShadeMidPoint + _CelShadeSoftness, NdotL);
    float litOrShadowAreaInverse = smoothstep(_CelShadeMidPoint + _CelShadeSoftness, _CelShadeMidPoint - _CelShadeSoftness, NdotL);
    float litShadowIntersection = litOrShadowArea * litOrShadowAreaInverse;
    litOrShadowArea = _IsFace ? lerp(0.5, 1, litOrShadowArea) : litOrShadowArea;
    litOrShadowArea *= lerp(1, attenuation, _ReceiveShadowMappingAmount);
    float3 litOrShadowColor = lerp(_ShadowTintColor, _LightTintColor, litOrShadowArea);
    litOrShadowColor = lerp(litOrShadowColor, _BorderTintColor, litShadowIntersection);
    float4 diffuseColor = float4(var_BaseMap.rgb * litOrShadowColor * lightColor.rgb, var_BaseMap.a);
    finalColor += diffuseColor;

    float4 var_matcap1st = 0;
    #ifdef _ENABLE_MATCAP_1ST
        var_matcap1st = SAMPLE_TEXTURE2D(_MatCap1st, sampler_MatCap1st, matcapUV) * _MatCap1stTintColor;
        float var_matcap1stMask = SAMPLE_TEXTURE2D(_MatCap1stMask, sampler_MatCap1stMask, input.uv).r;
        var_matcap1st = var_matcap1st * var_matcap1stMask * _MatCap1stMaskWeight;
        float3 matcap1stColor = lerp(var_matcap1st.rgb, var_matcap1st.rgb * var_BaseMap.rgb, _MatCap1stBlendWeight);
        finalColor.rgb = lexariaBlendColor(finalColor.rgb, matcap1stColor, var_matcap1st.a, _MatCap1stBlendMode);
    #endif
    float4 var_matcap2nd = 0;

    #ifdef _ENABLE_MATCAP_2ND
        var_matcap2nd = SAMPLE_TEXTURE2D(_MatCap2nd, sampler_MatCap2nd, matcapUV) * _MatCap2ndTintColor;
        float var_matcap2ndMask = SAMPLE_TEXTURE2D(_MatCap2ndMask, sampler_MatCap2ndMask, input.uv).r;
        var_matcap2nd = var_matcap2nd * var_matcap2ndMask * _MatCap2ndMaskWeight;
        float3 matcap2ndColor = lerp(var_matcap2nd.rgb, var_matcap2nd.rgb * var_BaseMap.rgb, _MatCap2ndBlendWeight);
        finalColor.rgb = lexariaBlendColor(finalColor.rgb, matcap2ndColor, var_matcap2nd.a, _MatCap2ndBlendMode);
    #endif

    finalColor.rgb += var_EmissionMap.rgb * _EmissionColor.rgb;

    float4 ambientColor = UNITY_LIGHTMODEL_AMBIENT * var_BaseMap;
    finalColor.rgb += ambientColor.rgb;
    
    #ifdef _PREMULTIPLY_ALPHA
        finalColor.rgb *= finalColor.a;
    #else
        finalColor = finalColor;
    #endif


    finalColor.rgb = ApplyFog(finalColor.rgb, input);
    return finalColor;
}

#endif