Shader "Lexaria/Toon"
{

	Properties
	{
		[Header(Texture)]
		[MainTexture] _BaseMap("Base Map (RGB) / Alpha (A)", 2D) = "white" {}
		[MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
		_ShadowMask ("Shadow Mask", 2D) = "white" {}
		_OutlineMask ("Outline Mask", 2D) = "white" {}
		_SpecularMask ("Specular Mask", 2D) = "black" {}
		_EmissionMap ("Emission Map", 2D) = "black" {}
		[HDR] _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
		
		[Toggle(_ENABLE_MATCAP)] _EnableMatCap("Enable Mat Cap?", float) = 1
		_MatCap ("MatCap", 2D) = "white" {}
		_MatCapWeight ("MatCap Weight", Range(0, 5)) = 1
		[Enum(Normal, 0, Add, 1, Screen, 2, Multi, 3)] _MatCapBlendMode ("MatCap Blend Mode", Float) = 0

		[Toggle(_ENABLE_SHADOWMASK)] _EnableShadowMask("Enable ShadowMask?", float) = 1
		[Toggle(_ENABLE_SHADOW)] _EnableShadow("Enable Shadow?", float) = 1
		[Header(Outline)]
		[Space(5)]
		[Toggle(_ENABLE_OUTLINE)] _EnableOutline("Enable Outline?", float) = 1
		_OutlineWidth ("Outline Width", Range(0, 1)) = 0.03
		_OutlineWidthMax ("Outline Width Max", Range(0, 3)) = 1
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		_OutlineDepthWeight ("Outline Depth Weight", Range(0, 10)) = 1
		_OutlineColorDepthWeight ("Outline Color Depth Weight", Range(0, 1)) = 0.5
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
		}
		Pass
		{
			Name "LexariaToonShading"
			Tags
			{
				"LightMode" = "UniversalForward"
			}
			Blend [_SrcBlend][_DstBlend]
			ZWrite [_ZWrite]
			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex ToonVert
			#pragma fragment ToonFrag
			#pragma shader_feature _PREMULTIPLY_ALPHA
			#pragma shader_feature _ENABLE_NORMALMAP
			#pragma shader_feature _ENABLE_SHADOW
			#pragma shader_feature _ENABLE_SHADOWMASK
			#pragma shader_feature _DEBUG
			#pragma shader_feature _ENABLE_MATCAP


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
			#include "ToonOutline.hlsl"
			ENDHLSL

			}
		UsePass "Universal Render Pipeline/Lit/ShadowCaster"
	}
	
	CustomEditor "LexariaCustomEditor"
}