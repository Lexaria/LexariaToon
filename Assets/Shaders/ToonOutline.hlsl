#ifndef TOON_OUTLINE_INCLUDED
#define TOON_OUTLINE_INCLUDED

Texture2D _BaseMap;
SamplerState sampler_BaseMap;

CBUFFER_START(UnityPerMaterial)
float _OutlineWidth;
float4 _OutlineColor;
float4 _BaseMap_ST;
CBUFFER_END


Texture2D _OutlineMask;
SamplerState sampler_OutlineMask;

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    float3 normalOS: NORMAL;
    float4 tangentOS: TANGENT;
    float4 color : COLOR;
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
    float4 positionWSAndOutlineFix : TEXCOORD1;

};

// FOV Correction
float GetCameraFOV()
{
    float t = unity_CameraProjection._m11;
    float Rad2Deg = 180 / 3.1415;
    float fov = atan(1.0f / t) * 2.0 * Rad2Deg;
    return fov;
}

float ApplyOutlineDistanceFadeOut(float inputMulFix)
{
    // Simple
    return saturate(1 / inputMulFix);
}

float GetOutlineCameraFovAndDistanceFixMultiplier(float positionVS_Z)
{
    float cameraMulFix;
    if(unity_OrthoParams.w == 0)
    {
        // Perspective Camera
        cameraMulFix = abs(positionVS_Z);
        cameraMulFix = ApplyOutlineDistanceFadeOut(cameraMulFix);
        cameraMulFix *= GetCameraFOV();
    }
    else
    {
        // Orthographic Camera
        float orthoSize = abs(unity_OrthoParams.y);
        orthoSize = ApplyOutlineDistanceFadeOut(orthoSize);
        cameraMulFix = orthoSize * 50;
    }
    return cameraMulFix * 0.00005;
}

float3 TransformPositionWSToOutlinePositionWS(float3 positionWS, float positionVS_Z, float3 normalWS, float outlineMask)
{
    float3 outlineExpandAmount = _OutlineWidth * GetOutlineCameraFovAndDistanceFixMultiplier(positionVS_Z);
    return positionWS + normalWS * outlineExpandAmount * outlineMask;
}

Varyings OutlineVert(Attributes IN)
{
    Varyings OUT;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS);
    #ifdef _SMOOTH_NORMAL_VERTEXCOLOR
        float3 vertexColorNormal = IN.color.xyz;
        VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(vertexColorNormal, IN.tangentOS);
    #else
        VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
    #endif
    
    float var_OutlineMask = SAMPLE_TEXTURE2D_LOD(_OutlineMask, sampler_OutlineMask, IN.uv, 0).r;
    float3 positionWS = vertexInput.positionWS;
    #ifdef _ENABLE_OUTLINE
        positionWS = TransformPositionWSToOutlinePositionWS(vertexInput.positionWS, vertexInput.positionVS.z, vertexNormalInput.normalWS, var_OutlineMask);
        float4 positionCS = TransformWorldToHClip(positionWS);
    #else
        float4 positionCS = vertexInput.positionCS;
    #endif
    OUT.positionCS = positionCS;
    OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
    OUT.positionWSAndOutlineFix.xyz = positionWS;
    OUT.positionWSAndOutlineFix.w = GetOutlineCameraFovAndDistanceFixMultiplier(vertexInput.positionVS.z);
    return OUT;
}

half4 OutlineFrag(Varyings IN) : SV_Target
{
    float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
    float3 outlineColor = lerp(_OutlineColor.rgb, var_BaseMap.rgb, saturate(IN.positionWSAndOutlineFix.w * 10));
    return half4(outlineColor, 1.0);
}


#endif