#ifndef LEXARIA_COMMON_FUNCTIONS_INCLUDED
#define LEXARIA_COMMON_FUNCTIONS_INCLUDED

// Color
float3 lexariaBlendColor(float3 dstColor, float3 srcColor, float3 srcA, uint blendMode)
{
    float3 ad = dstColor + srcColor;
    float3 mu = dstColor * srcColor;
    float3 outCol;
    if(blendMode == 0) outCol = srcColor; //Normal
    if(blendMode == 1) outCol = ad; //Add
    if(blendMode == 2) outCol = max(ad- mu, dstColor); // Screen
    if(blendMode == 3) outCol = mu;
    return lerp(dstColor, outCol, srcA);
}

float3 lexariaBlendColor(float3 dstColor, float3 srcColor, float srcA, uint blendMode)
{
    return lexariaBlendColor(dstColor, srcColor, float3(srcA, srcA, srcA), blendMode);
}


#endif