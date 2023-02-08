#ifndef TOON_SHADING_INCLUDED
#define TOON_SHADING_INCLUDED


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Lexaria_common_functions.hlsl"

Texture2D _BaseMap, _NormalMap, _ShadowMask, _MatCap, _EmissionMap;
SamplerState sampler_BaseMap, sampler_NormalMap, sampler_ShadowMask, sampler_MatCap, sampler_EmissionMap;

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float _BumpScale;
float _MatCapWeight, _MatCapBlendMode;
float4 _EmissionColor;
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
    float3 positionWS : TEXCOORD0;
    float2 uv: TEXCOORD1;
    float3 normalWS: TEXCOORD2;
    float3 tangentWS : TEXCOORD3;
    float3 bitangentWS : TEXCOORD4;
    
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord : TEXCOORD7;
    #endif
};


Varyings ToonVert(Attributes input)
{
    Varyings output = (Varyings)0;
    const VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(input.positionOS);
    const VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.positionCS = vertex_position_inputs.positionCS;
    output.positionWS = vertex_position_inputs.positionWS;
	
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

    output.normalWS = float3(vertex_normal_inputs.normalWS);
    output.tangentWS = float3(vertex_normal_inputs.tangentWS);
    output.bitangentWS = float3(vertex_normal_inputs.bitangentWS);

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertex_position_inputs);
    #endif
    return output;
}


half4 ToonFrag(Varyings input) : SV_Target
{
    float4 shadowCoord = float4(0, 0, 0, 0);
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
        shadowCoord = TransformWorldToShadowCoord(input.positionWS);
    #endif
    Light mainLight = GetMainLight(shadowCoord);
    float3 lightDir = normalize(mainLight.direction);
    float attenuation = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
    float3 lightColor = mainLight.color;
    float3 lightColorWithAttenuation = attenuation * lightColor;
    

    
    float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
    #ifdef _ENABLE_SHADOWMASK
    float4 var_ShadowMask = SAMPLE_TEXTURE2D(_ShadowMask, sampler_ShadowMask, input.uv);
    #endif
    float4 var_EmissionMap = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv);



    float3 normalWS;
    #ifdef _ENABLE_NORMALMAP
        float3 var_normalmap = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv), _BumpScale);
        normalWS = TransformTangentToWorld(var_normalmap, float3x3(input.tangentWS, input.bitangentWS, input.normalWS));
    #else
        normalWS = input.normalWS;
    #endif
        normalWS = NormalizeNormalPerPixel(normalWS);

    float3 normalVS = TransformWorldToViewDir(normalWS, true);
    float3 viewDirWS = normalize(GetCameraPositionWS() - input.positionWS);
    float3 viewDirVS = TransformWorldToViewDir(viewDirWS, true);
    float2 matcapUV = cross(normalVS, viewDirVS).xy;
    matcapUV = float2(-matcapUV.y, matcapUV.x) * 0.5 + 0.5;
    float NdotL = dot(normalWS, lightDir);
    float half_lambert = pow(NdotL * 0.5 + 0.5, 2);





    
    float4 finalColor;
    finalColor = float4(var_BaseMap.rgb * half_lambert * lightColorWithAttenuation, var_BaseMap.a);

    float4 var_matcap = 0;
    #ifdef _ENABLE_MATCAP
    var_matcap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, matcapUV);
    float3 matcapColor = lerp(var_matcap.rgb, var_matcap.rgb * var_BaseMap.rgb, _MatCapWeight);
    finalColor.rgb = lexariaBlendColor(finalColor.rgb, matcapColor, var_matcap.a, _MatCapBlendMode);
    #endif

    finalColor.rgb += var_EmissionMap.rgb * _EmissionColor.rgb;
    // finalColor += var_EmissionMap * _EmissionColor;

    #ifdef _PREMULTIPLY_ALPHA
        finalColor.rgb *= finalColor.a;
    #else
        finalColor = finalColor;
    #endif
    
    return finalColor;
}

#endif