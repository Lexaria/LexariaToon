#ifndef TOON_OUTLINE_INCLUDED
#define TOON_OUTLINE_INCLUDED

Texture2D _BaseMap;
SamplerState sampler_BaseMap;

CBUFFER_START(UnityPerMaterial)
float _OutlineWidth,_OutlineWidthMax;
float4 _OutlineColor;
float4 _BaseMap_ST;
float _OutlineDepthWeight, _OutlineColorDepthWeight;
CBUFFER_END


Texture2D _OutlineMask;
SamplerState sampler_OutlineMask;

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    float3 normalOS: NORMAL;
    float4 tangentOS: TANGENT;
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
};


Varyings OutlineVert(Attributes IN)
{
    Varyings OUT;
    float4 var_OutlineMask = SAMPLE_TEXTURE2D_LOD(_OutlineMask, sampler_OutlineMask, IN.uv, 0);
    float4 outlineDir = float4(GetVertexNormalInputs(IN.normalOS, IN.tangentOS).normalWS, 1.0);
    outlineDir = TransformWorldToHClip(outlineDir.xyz);
    VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(IN.positionOS);
    float4 positionCS = vertex_position_inputs.positionCS;
    #ifdef _ENABLE_OUTLINE
        float depth = positionCS.z / positionCS.w;
        depth = 1.0 / Linear01Depth(depth, _ZBufferParams);
        positionCS.xyz += normalize(outlineDir.xyz) * min(_OutlineWidth * 0.0001 * var_OutlineMask.x * (depth * _OutlineDepthWeight) * 0.01, _OutlineWidthMax * 0.01);
    #endif
    OUT.positionCS = positionCS;
    OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
    return OUT;
}

half4 OutlineFrag(Varyings IN) : SV_Target
{
    float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
    float depth = IN.positionCS.z / IN.positionCS.w;
    depth = saturate(Linear01Depth(depth, _ZBufferParams) * 1000);
    float3 outlineColor = lerp(_OutlineColor.rgb, var_BaseMap.rgb, saturate(depth - _OutlineColorDepthWeight));
    return half4(outlineColor, 1.0);
    // return var_BaseMap;
    
}


#endif