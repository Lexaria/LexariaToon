Shader "Lexaria/Toon"
{

	Properties
	{
		[Header(Texture)]
		[MainTexture] _BaseMap("Base Map (RGB) / Alpha (A)", 2D) = "white" {}
		[MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
		_OutlineMask ("Outline Mask", 2D) = "white" {}
		
		[Header(Cel Shading)]
		[Space(5)]
		[Toggle(_ISFACE)] _IsFace("Is Face?", float) = 0
		_CelShadeMidPoint ("Cel Shade Mid Point", Range(0, 1)) = 0.5
		_CelShadeSoftness ("Cel Shade Softness", Range(0,1)) = 0.05
		_LightTintColor ("Light Tint Color", Color) = (1, 1, 1, 1)
		_ShadowTintColor ("Shadow Tint Color", Color) = (1, 1, 1, 1)
		_BorderTintColor ("Border Tint Color", Color) = (1, 1, 1, 1)
		_ReceiveShadowMappingAmount ("Receive ShadowMapping Amount", Range(0, 1)) = 0.2
		[Space(30)]
		
		[Header(Emission)]
		[Space(5)]
		_EmissionMap ("Emission Map", 2D) = "black" {}
		[HDR] _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
		[Space(30)]
		
		
		[Header(Rim)]
		[Space(5)]
		_RimMask ("Rim Mask", 2D) = "white" {}
		_RimColor ("Rim Color", Color) = (1, 1, 1, 1)
		_RimMainStrength ("Rim Main Strength", Range(0, 1)) = 0.1
		_RimFresnelPower ("Rim FresnelPower", Range(0, 20)) = 1
		_RimOffset ("Rim Offset", Range(0, 0.01)) = 0.01
		_RimThreshold ("Rim Threshold", Range(0, 0.05)) = 0.01
		[Space(30)]		
		
		[Header(MatCap)]
		[Space(5)]
		[Toggle(_ENABLE_MATCAP_1ST)] _EnableMatCap1st("Enable 1st Mat Cap?", float) = 1
		[HDR] _MatCap1stTintColor ("1st Mat Cap Tint Color", Color) = (1, 1, 1, 1)
		_MatCap1st ("1st MatCap", 2D) = "white" {}
		_MatCap1stBlendWeight ("1st MatCap Blend Weight", Range(0, 5)) = 1
		[Enum(Normal, 0, Add, 1, Screen, 2, Multi, 3)] _MatCap1stBlendMode ("1st MatCap Blend Mode", Float) = 0
		_MatCap1stMask ("1st MatCap Mask", 2D) = "white" {}
		_MatCap1stMaskWeight ("1st MatCap Mask Weight", Range(0, 1)) = 1
		[Space(15)]
		[Toggle(_ENABLE_MATCAP_2ND)] _EnableMatCap2nd("Enable 2nd Mat Cap?", float) = 0
		[HDR] _MatCap2ndTintColor ("2nd Mat Cap Tint Color", Color) = (1, 1, 1, 1)
		_MatCap2nd ("2nd MatCap", 2D) = "white" {}
		_MatCap2ndBlendWeight ("2nd MatCap Blend Weight", Range(0, 5)) = 1
		[Enum(Normal, 0, Add, 1, Screen, 2, Multi, 3)] _MatCap2ndBlendMode ("2nd MatCap Blend Mode", Float) = 0
		_MatCap2ndMask ("2nd MatCap Mask", 2D) = "white" {}
		_MatCap2ndMaskWeight ("2nd MatCap Mask Weight", Range(0, 1)) = 1
		[Space(30)]
		
		[Header(ShadowMap)]
		[Space(5)]
		_ShadowMask ("Shadow Mask", 2D) = "white" {}
		[Toggle(_ENABLE_SHADOWMASK)] _EnableShadowMask("Enable ShadowMask?", float) = 1
		[Toggle(_ENABLE_SHADOW)] _EnableShadow("Enable Shadow?", float) = 1
		[Space(30)]
		
		[Header(Outline)]
		[Space(5)]
		[Toggle(_ENABLE_OUTLINE)] _EnableOutline("Enable Outline?", float) = 1
		_OutlineWidth ("Outline Width", Range(0, 5)) = 0.5
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		[Toggle(_SMOOTH_NORMAL_VERTEXCOLOR)] _SmoothNormalVertexColor("Use Smoothed Normal in Vertex Color ?", float) = 0
		[Space(30)]
		
		[Header(Normal)]
		[Toggle(_ENABLE_NORMALMAP)] _EnableNormalMap("Enable NormalMap?", float) = 0
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_BumpScale ("Bump Scale", Range(0, 10)) = 1
		[Space(30)]

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1
		[Toggle(_PREMULTIPLY_ALPHA)] _PremulAlpha("Premultiply Alpha", Float) = 0

		[Toggle(_ALPHATEST_ON)] _AlphaTestToggle ("Alpha Clipping", Float) = 0
		_Cutoff ("Alpha Cutoff", Float) = 0.5

		[Toggle(_DEBUG)] _DEBUG ("DEBUG", Float) = 0

	}
	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry"
		}
		Pass
		{
			Name "LexariaToonShading"
			Tags
			{
				"LightMode" = "UniversalForward"
			}
			Blend [_SrcBlend][_DstBlend]
			ZTest LEqual
			ZWrite [_ZWrite]
			Cull Back
			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex ToonVert
			#pragma fragment ToonFrag
			#pragma shader_feature _PREMULTIPLY_ALPHA
			#pragma shader_feature _ENABLE_NORMALMAP
			#pragma shader_feature _ENABLE_SHADOW
			#pragma shader_feature _ENABLE_SHADOWMASK
			#pragma shader_feature _ENABLE_MATCAP_1ST
			#pragma shader_feature _ENABLE_MATCAP_2ND
			#pragma shader_feature _DEBUG


			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING // v10+ only, renamed from "_MIXED_LIGHTING_SUBTRACTIVE"
			#pragma multi_compile _ SHADOWS_SHADOWMASK // v10+ only
			#include "ToonShading.hlsl"
			ENDHLSL
		}
		Pass
		{
			Name "LexariaToonOutline"
			Tags
			{
				"LightMode" = "SRPDefaultUnlit"
			}
			Cull Front

			HLSLPROGRAM
			#pragma vertex OutlineVert
			#pragma fragment OutlineFrag
			#include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#pragma shader_feature _ENABLE_OUTLINE
			#pragma shader_feature _SMOOTH_NORMAL_VERTEXCOLOR
			#include "ToonOutline.hlsl"
			ENDHLSL

		}
		UsePass "Universal Render Pipeline/Lit/ShadowCaster"
		UsePass "Universal Render Pipeline/Lit/DepthOnly"
		UsePass "Universal Render Pipeline/Lit/DepthNormals"
	}
	
	CustomEditor "LexariaCustomEditor"
}