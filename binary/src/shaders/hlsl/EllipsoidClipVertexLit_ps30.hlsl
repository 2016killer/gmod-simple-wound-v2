//===================== Copyright (c) Valve Corporation. All Rights Reserved. ======================
//
// Pixel shader for EllipsoidClipVertexLit.
//
//==================================================================================================

// STATIC: "CONVERT_TO_SRGB"			"0..0"
// STATIC: "FLASHLIGHT"					"0..1"
// STATIC: "FLASHLIGHTDEPTHFILTERMODE"	"0..2"
// STATIC: "BUMPMAP"					"0..1"
// STATIC: "PHONG"						"0..1"
// STATIC: "PHONGEXPONENTTEXTURE"		"0..1"
// STATIC: "PHONGALBEDOTINT"			"0..1"
// STATIC: "BASEMAPALPHAPHONGMASK"		"0..1"
// STATIC: "HALFLAMBERT"				"0..1"
// STATIC: "RIMLIGHT"					"0..1"
// STATIC: "RIMMASK"					"0..1"

// DYNAMIC: "WRITEWATERFOGTODESTALPHA"	"0..1"
// DYNAMIC: "PIXELFOGTYPE"				"0..1"
// DYNAMIC: "NUM_LIGHTS"				"0..4"
// DYNAMIC: "WRITE_DEPTH_TO_DESTALPHA"	"0..1"
// DYNAMIC: "FLASHLIGHTSHADOWS"			"0..1"

// SKIP: ($PIXELFOGTYPE == 0) && ($WRITEWATERFOGTODESTALPHA != 0)
// SKIP: ( $FLASHLIGHT == 0 ) && ( $FLASHLIGHTSHADOWS == 1 )
// SKIP: ( $FLASHLIGHT == 0 ) && ( $FLASHLIGHTDEPTHFILTERMODE != 0 )
// SKIP: ( $PHONG == 0 ) && ( $RIMLIGHT == 1 )
// SKIP: ( $PHONGEXPONENTTEXTURE == 0 ) && ( $PHONGALBEDOTINT == 1 )
// SKIP: ( $PHONGEXPONENTTEXTURE == 0 ) && ( $RIMMASK == 1 )

#include "common_flashlight_fxc.h"
#include "common_vertexlitgeneric_dx9.h"
#include "shader_constant_register_map.h"

const float4 g_DiffuseModulation		: register( PSREG_DIFFUSE_MODULATION );
const float4 g_ShadowTweaks				: register( PSREG_ENVMAP_TINT__SHADOW_TWEAKS );
const float3 cAmbientCube[6]			: register( PSREG_AMBIENT_CUBE );
const float4 g_EyePos_SpecExponent		: register( PSREG_EYEPOS_SPEC_EXPONENT );
const float4 g_FresnelSpecParams		: register( PSREG_FRESNEL_SPEC_PARAMS );
const float4 g_SpecularRimParams		: register( PSREG_SPEC_RIM_PARAMS );
const float4 g_FogParams				: register( PSREG_FOG_PARAMS );
const float4 g_FlashlightAttenuationFactors_RimMask : register( PSREG_FLASHLIGHT_ATTENUATION );
const float4 g_FlashlightPos_RimBoost	: register( PSREG_FLASHLIGHT_POSITION_RIM_BOOST );
const float4x4 g_FlashlightWorldToTexture : register( PSREG_FLASHLIGHT_TO_WORLD_TEXTURE );
PixelShaderLightInfo cLightInfo[3]		: register( PSREG_LIGHT_INFO_ARRAY );

#define g_FlashlightAttenuationFactors g_FlashlightAttenuationFactors_RimMask
#define g_FlashlightPos g_FlashlightPos_RimBoost.xyz
#define g_FresnelRanges g_FresnelSpecParams.xyz
#define g_SpecularBoost g_FresnelSpecParams.w
#define g_SpecularTint g_SpecularRimParams.xyz
#define g_RimExponent g_SpecularRimParams.w

sampler BaseTextureSampler		: register( s0 );
sampler ProjTextureSampler		: register( s2 );
sampler BumpmapSampler			: register( s3 );
sampler ShadowDepthSampler		: register( s4 );
sampler NormalizeRandRotSampler	: register( s5 );
sampler FlashlightSampler		: register( s6 );
sampler SpecExponentSampler		: register( s7 );

const float g_BloodRange : register( PSREG_CONSTANT_03 );

struct PS_INPUT
{
	float2 baseTexCoord		: TEXCOORD0;
	float4 lightAtten		: TEXCOORD1;
	float3 worldNormal		: TEXCOORD2;
	float3 worldPos			: TEXCOORD3;
	float4 worldTangent		: TEXCOORD4;
	float4 woundData01		: TEXCOORD5;
	float4 woundData2		: TEXCOORD6;
	float4 woundTail		: TEXCOORD7;
};

void AccumProjected(
	float3 woundData,
	out float3 rgb,
	out float weight
)
{
	float2 uv = woundData.xy;
	float dist = woundData.z;
	float4 projColor = tex2D( ProjTextureSampler, uv );
	float distFactor = 1 - smoothstep(1.0, 1.0 + g_BloodRange, dist);
	weight = distFactor;
	rgb = weight * projColor.rgb;
}

float4 main( PS_INPUT i ) : COLOR
{
	float4 baseColor = tex2D( BaseTextureSampler, i.baseTexCoord );
	float3 woundData0 = float3( i.woundData01.xy, i.woundData2.z );
	float3 woundData1 = float3( i.woundData01.zw, i.woundData2.w );
	float3 woundData2 = float3( i.woundData2.xy, i.woundTail.x );
	float2 bumpTexCoord = i.woundTail.yz;
	float minDist = min( min( woundData0.z, woundData1.z ), woundData2.z );
	clip( minDist - 1.0 );

	float3 rgb0, rgb1, rgb2;
	float w0, w1, w2;
	AccumProjected( woundData0, rgb0, w0 );
	AccumProjected( woundData1, rgb1, w1 );
	AccumProjected( woundData2, rgb2, w2 );
	float totalW = saturate( w0 + w1 + w2 );
	float safeW = max( totalW, 1e-6 );
	float3 projColor = ( rgb0 + rgb1 + rgb2 ) / safeW;
	float3 baseAlbedo = baseColor.rgb * g_DiffuseModulation.rgb;
	float3 woundAlbedo = lerp( baseAlbedo, projColor, totalW );

	float3 worldSpaceNormal = normalize( i.worldNormal );
	float fSpecMask = baseColor.a;

#if BUMPMAP
	float3 vWorldBinormal =
		cross( i.worldNormal.xyz, i.worldTangent.xyz ) * i.worldTangent.w;
	float4 normalTexel = tex2D( BumpmapSampler, bumpTexCoord );
	float3 tangentSpaceNormal = normalTexel.xyz * 2.0f - 1.0f;
	worldSpaceNormal = normalize(
		Vec3TangentToWorld(
			tangentSpaceNormal,
			i.worldNormal,
			i.worldTangent.xyz,
			vWorldBinormal
		)
	);
	fSpecMask = normalTexel.a;
#endif

#if BASEMAPALPHAPHONGMASK
	worldSpaceNormal = normalize( i.worldNormal );
	fSpecMask = baseColor.a;
#endif

	float3 diffuseLighting;
	if ( FLASHLIGHT != 0 )
	{
		float4 flashlightSpacePosition =
			mul( float4( i.worldPos, 1.0f ), g_FlashlightWorldToTexture );

		diffuseLighting = DoFlashlight(
			g_FlashlightPos,
			i.worldPos,
			flashlightSpacePosition,
			worldSpaceNormal,
			g_FlashlightAttenuationFactors.xyz,
			g_FlashlightAttenuationFactors.w,
			FlashlightSampler,
			ShadowDepthSampler,
			NormalizeRandRotSampler,
			FLASHLIGHTDEPTHFILTERMODE,
			FLASHLIGHTSHADOWS,
			true,
			float3( 0.0f, 0.0f, 0.0f ),
			false,
			g_ShadowTweaks
		);
	}
	else
	{
		diffuseLighting = PixelShaderDoLighting(
			i.worldPos,
			worldSpaceNormal,
			float3( 0.0f, 0.0f, 0.0f ),
			false,
			true,
			i.lightAtten,
			cAmbientCube,
			NormalizeRandRotSampler,
			NUM_LIGHTS,
			cLightInfo,
			HALFLAMBERT != 0,
			false,
			1.0f,
			false,
			BaseTextureSampler
		);
	}

	float3 albedo = woundAlbedo;
	float3 diffuseComponent = albedo * diffuseLighting;
	float3 specularLighting = float3( 0.0f, 0.0f, 0.0f );
	float3 vSpecularTint = float3( 1.0f, 1.0f, 1.0f );

#if PHONG
	float3 vEyeDir = normalize( g_EyePos_SpecExponent.xyz - i.worldPos );
	float4 specExpMap = float4( 1.0f, 1.0f, 1.0f, 1.0f );
	float fSpecExp;

#if PHONGEXPONENTTEXTURE
	specExpMap = tex2D( SpecExponentSampler, i.baseTexCoord );
	fSpecExp =
		(g_EyePos_SpecExponent.w >= 0.0f)
			? g_EyePos_SpecExponent.w
			: (1.0f + 149.0f * specExpMap.r);
#if PHONGALBEDOTINT
	vSpecularTint = lerp(
		float3( 1.0f, 1.0f, 1.0f ),
		baseColor.rgb,
		specExpMap.g
	);
#endif
#else
	fSpecExp = max( g_EyePos_SpecExponent.w, 5.0f );
#endif

	if ( g_SpecularTint.r >= 0.0f )
	{
		vSpecularTint = g_SpecularTint;
	}

	float fFresnelRanges = Fresnel(
		worldSpaceNormal,
		vEyeDir,
		g_FresnelRanges
	);
	float3 rimLighting = float3( 0.0f, 0.0f, 0.0f );

	PixelShaderDoSpecularLighting(
		i.worldPos,
		worldSpaceNormal,
		fSpecExp,
		vEyeDir,
		i.lightAtten,
		NUM_LIGHTS,
		cLightInfo,
		false,
		1.0f,
		false,
		BaseTextureSampler,
		fFresnelRanges,
		RIMLIGHT != 0,
		g_RimExponent,
		specularLighting,
		rimLighting
	);

	fSpecMask *= fFresnelRanges;
	specularLighting *= fSpecMask * g_SpecularBoost;

#if RIMLIGHT
	float fRimFresnel = Fresnel4( worldSpaceNormal, vEyeDir );
	float fRimMask = 1.0f;
#if RIMMASK
	fRimMask = specExpMap.a;
#endif
	float fRimMultiply = fRimMask * fRimFresnel;
	rimLighting *= fRimMultiply;
	specularLighting = max( specularLighting, rimLighting );

	float3 rimAmbientCubeColor = PixelShaderAmbientLight(
		vEyeDir,
		cAmbientCube
	);
	specularLighting +=
		(rimAmbientCubeColor * g_FlashlightPos_RimBoost.w) *
		saturate( fRimMultiply * worldSpaceNormal.z );
#endif
#endif

	float3 result =
		diffuseComponent +
		specularLighting * vSpecularTint;

	float alpha = g_DiffuseModulation.a;
#if !(PHONG && BASEMAPALPHAPHONGMASK)
	alpha *= baseColor.a;
#endif

	float fogFactor = CalcPixelFogFactor(
		PIXELFOGTYPE,
		g_FogParams,
		g_EyePos_SpecExponent.xyz,
		i.worldPos.z,
		i.woundTail.w
	);

#if WRITEWATERFOGTODESTALPHA && ( PIXELFOGTYPE == PIXEL_FOG_TYPE_HEIGHT )
	alpha = fogFactor;
#endif

	bool bWriteDepthToAlpha =
		(WRITE_DEPTH_TO_DESTALPHA != 0) &&
		(WRITEWATERFOGTODESTALPHA == 0);

	return FinalOutput(
		float4( result, alpha ),
		fogFactor,
		PIXELFOGTYPE,
		TONEMAP_SCALE_LINEAR,
		bWriteDepthToAlpha,
		i.woundTail.w
	);
}
