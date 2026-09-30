#pragma once

#include "BaseVSShader.h"
#include "cpp_shader_constant_register_map.h"

#include "shaders/inc/EllipsoidClipVertexLit_vs30.inc"
#include "shaders/inc/EllipsoidClipVertexLit_ps30.inc"

#include <string.h>

static inline float SW2ECNormCenter(float value)
{
	float normalized = (value + 500.0f) / 1000.0f;
	return normalized < 0.0f ? 0.0f : (normalized > 0.9999f ? 0.9999f : normalized);
}

static inline float SW2ECNormAngle(float value)
{
	float wrapped = fmod(value, 6.2831853f);
	if (wrapped < 0.0f)
		wrapped += 6.2831853f;
	return wrapped / 6.2831853f;
}

static inline float SW2ECNormRadius(float value)
{
	float normalized = value / 100.0f;
	return normalized < 0.0f ? 0.0f : (normalized > 0.9999f ? 0.9999f : normalized);
}

static inline float SW2ECPack2(float a, float b)
{
	return a + floor(b * 2048.0f + 0.5f);
}

BEGIN_VS_SHADER(EllipsoidClipVertexLit, "Help for EllipsoidClipVertexLit")

BEGIN_SHADER_PARAMS
	SHADER_PARAM(ALPHATESTREFERENCE, SHADER_PARAM_TYPE_FLOAT, "0.0", "")
	SHADER_PARAM(BUMPMAP, SHADER_PARAM_TYPE_TEXTURE, "", "bump map")
	SHADER_PARAM(BUMPFRAME, SHADER_PARAM_TYPE_INTEGER, "0", "bump map frame")
	SHADER_PARAM(BUMPTRANSFORM, SHADER_PARAM_TYPE_MATRIX, "center .5 .5 scale 1 1 rotate 0 translate 0 0", "bump map transform")
	SHADER_PARAM(PHONG, SHADER_PARAM_TYPE_BOOL, "0", "enables phong lighting")
	SHADER_PARAM(PHONGEXPONENT, SHADER_PARAM_TYPE_FLOAT, "0.0", "phong exponent")
	SHADER_PARAM(PHONGEXPONENTTEXTURE, SHADER_PARAM_TYPE_TEXTURE, "", "phong exponent map")
	SHADER_PARAM(PHONGTINT, SHADER_PARAM_TYPE_COLOR, "[1 1 1]", "phong tint")
	SHADER_PARAM(PHONGALBEDOTINT, SHADER_PARAM_TYPE_BOOL, "1", "use the green channel of the exponent map as phong tint")
	SHADER_PARAM(PHONGBOOST, SHADER_PARAM_TYPE_FLOAT, "1.0", "phong boost")
	SHADER_PARAM(PHONGFRESNELRANGES, SHADER_PARAM_TYPE_VEC3, "[0 0.5 1]", "phong fresnel ranges")
	SHADER_PARAM(BASEMAPALPHAPHONGMASK, SHADER_PARAM_TYPE_BOOL, "0", "use base alpha as the phong mask")
	SHADER_PARAM(RIMLIGHT, SHADER_PARAM_TYPE_BOOL, "0", "enables rim lighting")
	SHADER_PARAM(RIMLIGHTEXPONENT, SHADER_PARAM_TYPE_FLOAT, "4.0", "rim light exponent")
	SHADER_PARAM(RIMLIGHTBOOST, SHADER_PARAM_TYPE_FLOAT, "1.0", "rim light boost")
	SHADER_PARAM(RIMMASK, SHADER_PARAM_TYPE_BOOL, "0", "use exponent map alpha as the rim mask")
	SHADER_PARAM(ELLIPSOID_CENTER_1, SHADER_PARAM_TYPE_VEC3, "[499 499 499]", "Ellipsoid center based on pre-skinned space")
	SHADER_PARAM(ELLIPSOID_ANGLE_1, SHADER_PARAM_TYPE_VEC3, "[0 0 0]", "Ellipsoid angle based on pre-skinned space")
	SHADER_PARAM(ELLIPSOID_SCALE_1, SHADER_PARAM_TYPE_VEC3, "[0.025 0.025 0.025]", "Ellipsoid scale based on pre-skinned space")
	SHADER_PARAM(ELLIPSOID_CENTER_2, SHADER_PARAM_TYPE_VEC3, "[499 499 499]", "Ellipsoid center based on pre-skinned space")
	SHADER_PARAM(ELLIPSOID_ANGLE_2, SHADER_PARAM_TYPE_VEC3, "[0 0 0]", "Ellipsoid angle based on pre-skinned space")
	SHADER_PARAM(ELLIPSOID_SCALE_2, SHADER_PARAM_TYPE_VEC3, "[0.025 0.025 0.025]", "Ellipsoid scale based on pre-skinned space")
	SHADER_PARAM(ELLIPSOID_CENTER_3, SHADER_PARAM_TYPE_VEC3, "[499 499 499]", "Ellipsoid center based on pre-skinned space")
	SHADER_PARAM(ELLIPSOID_ANGLE_3, SHADER_PARAM_TYPE_VEC3, "[0 0 0]", "Ellipsoid angle based on pre-skinned space")
	SHADER_PARAM(ELLIPSOID_SCALE_3, SHADER_PARAM_TYPE_VEC3, "[0.025 0.025 0.025]", "Ellipsoid scale based on pre-skinned space")
	SHADER_PARAM(BLOOD_RANGE, SHADER_PARAM_TYPE_FLOAT, "0.5", "Blood texture range")
	SHADER_PARAM(PROJECT_TEXTURE, SHADER_PARAM_TYPE_TEXTURE, "models/flesh", "Projected texture")
END_SHADER_PARAMS

SHADER_INIT_PARAMS()
{
	SET_FLAGS2(MATERIAL_VAR2_SUPPORTS_HW_SKINNING);
	SET_FLAGS2(MATERIAL_VAR2_LIGHTING_VERTEX_LIT);

	InitIntParam(PHONG, params, 0);
	InitFloatParam(PHONGEXPONENT, params, 0.0f);
	InitIntParam(PHONGALBEDOTINT, params, 1);
	InitFloatParam(PHONGBOOST, params, 1.0f);
	InitIntParam(BASEMAPALPHAPHONGMASK, params, 0);
	InitIntParam(RIMLIGHT, params, 0);
	InitFloatParam(RIMLIGHTEXPONENT, params, 4.0f);
	InitFloatParam(RIMLIGHTBOOST, params, 1.0f);
	InitIntParam(RIMMASK, params, 0);

	if (!params[PHONGTINT]->IsDefined())
	{
		params[PHONGTINT]->SetVecValue(1.0f, 1.0f, 1.0f);
	}

	if (!params[PHONGFRESNELRANGES]->IsDefined())
	{
		params[PHONGFRESNELRANGES]->SetVecValue(0.0f, 0.5f, 1.0f);
	}

	if (g_pConfig->UseBumpmapping() && params[BUMPMAP]->IsDefined())
	{
		SET_FLAGS2(MATERIAL_VAR2_NEEDS_TANGENT_SPACES);
	}

	if (!params[ELLIPSOID_CENTER_1]->IsDefined())
		params[ELLIPSOID_CENTER_1]->SetVecValue(0.0f, 0.0f, 0.0f);
	if (!params[ELLIPSOID_ANGLE_1]->IsDefined())
		params[ELLIPSOID_ANGLE_1]->SetVecValue(0.0f, 0.0f, 0.0f);
	if (!params[ELLIPSOID_SCALE_1]->IsDefined())
		params[ELLIPSOID_SCALE_1]->SetVecValue(0.0f, 0.0f, 0.0f);
	if (!params[ELLIPSOID_CENTER_2]->IsDefined())
		params[ELLIPSOID_CENTER_2]->SetVecValue(0.0f, 0.0f, 0.0f);
	if (!params[ELLIPSOID_ANGLE_2]->IsDefined())
		params[ELLIPSOID_ANGLE_2]->SetVecValue(0.0f, 0.0f, 0.0f);
	if (!params[ELLIPSOID_SCALE_2]->IsDefined())
		params[ELLIPSOID_SCALE_2]->SetVecValue(0.0f, 0.0f, 0.0f);
	if (!params[ELLIPSOID_CENTER_3]->IsDefined())
		params[ELLIPSOID_CENTER_3]->SetVecValue(0.0f, 0.0f, 0.0f);
	if (!params[ELLIPSOID_ANGLE_3]->IsDefined())
		params[ELLIPSOID_ANGLE_3]->SetVecValue(0.0f, 0.0f, 0.0f);
	if (!params[ELLIPSOID_SCALE_3]->IsDefined())
		params[ELLIPSOID_SCALE_3]->SetVecValue(0.0f, 0.0f, 0.0f);
	if (!params[BLOOD_RANGE]->IsDefined())
		params[BLOOD_RANGE]->SetFloatValue(0.5f);

	if (!params[FLASHLIGHTTEXTURE]->IsDefined())
	{
		params[FLASHLIGHTTEXTURE]->SetStringValue(
			g_pHardwareConfig->SupportsBorderColor()
				? "effects/flashlight_border"
				: "effects/flashlight001"
		);
	}
}

SHADER_FALLBACK
{
	return 0;
}

SHADER_INIT
{
	LoadTexture(FLASHLIGHTTEXTURE, TEXTUREFLAGS_SRGB);

	if (params[BASETEXTURE]->IsDefined())
	{
		LoadTexture(BASETEXTURE, TEXTUREFLAGS_SRGB);
	}

	if (g_pConfig->UseBumpmapping() && params[BUMPMAP]->IsDefined())
	{
		LoadBumpMap(BUMPMAP);
		SET_FLAGS2(MATERIAL_VAR2_DIFFUSE_BUMPMAPPED_MODEL);
	}

	if (
		params[PHONG]->GetIntValue() != 0 &&
		params[PHONGEXPONENTTEXTURE]->IsDefined()
	)
	{
		LoadTexture(PHONGEXPONENTTEXTURE);
	}

	if (params[PROJECT_TEXTURE]->IsDefined())
	{
		LoadTexture(PROJECT_TEXTURE);
	}
}

void DrawWoundVertexLit(
	CBaseVSShader* pShader,
	IMaterialVar** params,
	IShaderDynamicAPI* pShaderAPI,
	IShaderShadow* pShaderShadow,
	bool bHasFlashlight,
	VertexCompressionType_t vertexCompression
)
{
	bool bHasBaseTexture = params[BASETEXTURE]->IsTexture();
	bool bIsAlphaTested = IS_FLAG_SET(MATERIAL_VAR_ALPHATEST) != 0;
	bool bHasBump =
		g_pConfig->UseBumpmapping() &&
		params[BUMPMAP]->IsTexture();
	bool bHasPhong =
		!bHasFlashlight &&
		params[PHONG]->GetIntValue() != 0;
	bool bHasPhongExponentTexture =
		bHasPhong &&
		params[PHONGEXPONENTTEXTURE]->IsTexture();
	bool bHasPhongTintMap =
		bHasPhongExponentTexture &&
		params[PHONGALBEDOTINT]->GetIntValue() != 0;
	bool bHasRimLight =
		bHasPhong &&
		params[RIMLIGHT]->GetIntValue() != 0;
	bool bHasRimMaskMap =
		bHasRimLight &&
		bHasPhongExponentTexture &&
		params[RIMMASK]->GetIntValue() != 0;
	bool bBaseMapAlphaPhongMask =
		params[BASEMAPALPHAPHONGMASK]->GetIntValue() != 0;
	bool bHalfLambert =
		bHasPhong ||
		IS_FLAG_SET(MATERIAL_VAR_HALFLAMBERT);

	bool bFullyOpaque =
		!IS_FLAG_SET(MATERIAL_VAR_TRANSLUCENT) &&
		!bIsAlphaTested &&
		!bHasFlashlight;

	if (pShader->IsSnapshotting())
	{
		pShaderShadow->EnableAlphaTest(bIsAlphaTested);

		if (params[ALPHATESTREFERENCE]->GetFloatValue() > 0.0f)
		{
			pShaderShadow->AlphaFunc(
				SHADER_ALPHAFUNC_GEQUAL,
				params[ALPHATESTREFERENCE]->GetFloatValue()
			);
		}

		int nShadowFilterMode = 0;
		if (bHasFlashlight)
		{
			if (bHasBaseTexture)
			{
				pShader->SetAdditiveBlendingShadowState(BASETEXTURE, true);
			}

			if (bIsAlphaTested)
			{
				pShaderShadow->EnableAlphaTest(false);
				pShaderShadow->DepthFunc(SHADER_DEPTHFUNC_EQUAL);
			}

			pShaderShadow->EnableBlending(true);
			pShaderShadow->EnableDepthWrites(false);
			pShaderShadow->EnableAlphaWrites(false);
			nShadowFilterMode = g_pHardwareConfig->GetShadowFilterMode();
		}
		else if (bHasBaseTexture)
		{
			pShader->SetDefaultBlendingShadowState(BASETEXTURE, true);
		}

		pShaderShadow->EnableTexture(SHADER_SAMPLER0, true);
		pShaderShadow->EnableSRGBRead(SHADER_SAMPLER0, true);
		pShaderShadow->EnableTexture(SHADER_SAMPLER1, true);
		pShaderShadow->EnableTexture(SHADER_SAMPLER2, true);
		pShaderShadow->EnableSRGBRead(SHADER_SAMPLER2, true);

		if (bHasBump)
		{
			pShaderShadow->EnableTexture(SHADER_SAMPLER3, true);
			pShaderShadow->EnableSRGBRead(SHADER_SAMPLER3, false);
		}

		if (bHasPhongExponentTexture)
		{
			pShaderShadow->EnableTexture(SHADER_SAMPLER7, true);
			pShaderShadow->EnableSRGBRead(SHADER_SAMPLER7, false);
		}

		if (bHasFlashlight)
		{
			pShaderShadow->EnableTexture(SHADER_SAMPLER4, true);
			pShaderShadow->SetShadowDepthFiltering(SHADER_SAMPLER4);
			pShaderShadow->EnableSRGBRead(SHADER_SAMPLER4, false);
			pShaderShadow->EnableTexture(SHADER_SAMPLER5, true);
			pShaderShadow->EnableTexture(SHADER_SAMPLER6, true);
			pShaderShadow->EnableSRGBRead(SHADER_SAMPLER6, true);
		}

		pShaderShadow->EnableTexture(SHADER_SAMPLER5, true);
		pShaderShadow->EnableSRGBWrite(true);

		int pTexCoordDim[3] = { 2, 0, 3 };
		int flags = VERTEX_POSITION | VERTEX_NORMAL | VERTEX_FORMAT_COMPRESSED;
		int userDataSize = bHasBump ? 4 : 0;
		pShaderShadow->VertexShaderVertexFormat(
			flags,
			1,
			pTexCoordDim,
			userDataSize
		);

		DECLARE_STATIC_VERTEX_SHADER(EllipsoidClipVertexLit_vs30);
		SET_STATIC_VERTEX_SHADER_COMBO(BUMPMAP, bHasBump);
		SET_STATIC_VERTEX_SHADER(EllipsoidClipVertexLit_vs30);

		DECLARE_STATIC_PIXEL_SHADER(EllipsoidClipVertexLit_ps30);
		SET_STATIC_PIXEL_SHADER_COMBO(FLASHLIGHT, bHasFlashlight);
		SET_STATIC_PIXEL_SHADER_COMBO(FLASHLIGHTDEPTHFILTERMODE, nShadowFilterMode);
		SET_STATIC_PIXEL_SHADER_COMBO(BUMPMAP, bHasBump);
		SET_STATIC_PIXEL_SHADER_COMBO(PHONG, bHasPhong);
		SET_STATIC_PIXEL_SHADER_COMBO(
			PHONGEXPONENTTEXTURE,
			bHasPhongExponentTexture
		);
		SET_STATIC_PIXEL_SHADER_COMBO(PHONGALBEDOTINT, bHasPhongTintMap);
		SET_STATIC_PIXEL_SHADER_COMBO(
			BASEMAPALPHAPHONGMASK,
			bBaseMapAlphaPhongMask
		);
		SET_STATIC_PIXEL_SHADER_COMBO(HALFLAMBERT, bHalfLambert);
		SET_STATIC_PIXEL_SHADER_COMBO(RIMLIGHT, bHasRimLight);
		SET_STATIC_PIXEL_SHADER_COMBO(RIMMASK, bHasRimMaskMap);
		SET_STATIC_PIXEL_SHADER_COMBO(CONVERT_TO_SRGB, 0);
		SET_STATIC_PIXEL_SHADER(EllipsoidClipVertexLit_ps30);

		if (bHasFlashlight)
		{
			pShader->FogToBlack();
		}
		else
		{
			pShader->DefaultFog();
		}

		pShaderShadow->EnableAlphaWrites(bFullyOpaque);
	}
	else
	{
		if (bHasBaseTexture)
		{
			pShader->BindTexture(SHADER_SAMPLER0, BASETEXTURE, FRAME);
		}
		else
		{
			pShaderAPI->BindStandardTexture(SHADER_SAMPLER0, TEXTURE_WHITE);
		}

		pShader->BindTexture(SHADER_SAMPLER2, PROJECT_TEXTURE);

		if (bHasBump)
		{
			pShader->BindTexture(SHADER_SAMPLER3, BUMPMAP, BUMPFRAME);
		}
		else if (bHasPhong)
		{
			pShaderAPI->BindStandardTexture(
				SHADER_SAMPLER3,
				TEXTURE_NORMALMAP_FLAT
			);
		}

		if (bHasPhongExponentTexture)
		{
			pShader->BindTexture(
				SHADER_SAMPLER7,
				PHONGEXPONENTTEXTURE
			);
		}
		else if (bHasPhong)
		{
			pShaderAPI->BindStandardTexture(SHADER_SAMPLER7, TEXTURE_WHITE);
		}

		LightState_t lightState = { 0, false, false };
		bool bFlashlightShadows = false;

		if (bHasFlashlight)
		{
			pShader->BindTexture(SHADER_SAMPLER6, FLASHLIGHTTEXTURE, FLASHLIGHTTEXTUREFRAME);

			VMatrix worldToTexture;
			ITexture* pFlashlightDepthTexture;
			FlashlightState_t state =
				pShaderAPI->GetFlashlightStateEx(worldToTexture, &pFlashlightDepthTexture);

			bFlashlightShadows =
				state.m_bEnableShadows &&
				pFlashlightDepthTexture != NULL;

			SetFlashLightColorFromState(state, pShaderAPI, PSREG_FLASHLIGHT_COLOR);

			if (
				pFlashlightDepthTexture &&
				g_pConfig->ShadowDepthTexture() &&
				state.m_bEnableShadows
			)
			{
				pShader->BindTexture(SHADER_SAMPLER4, pFlashlightDepthTexture, 0);
				pShaderAPI->BindStandardTexture(SHADER_SAMPLER5, TEXTURE_SHADOW_NOISE_2D);
			}
		}
		else
		{
			pShaderAPI->GetDX9LightState(&lightState);
		}

		MaterialFogMode_t fogType = pShaderAPI->GetSceneFogMode();
		int fogIndex = fogType == MATERIAL_FOG_LINEAR_BELOW_FOG_Z ? 1 : 0;
		int numBones = pShaderAPI->GetCurrentNumBones();

		bool bWriteDepthToAlpha = false;
		bool bWriteWaterFogToAlpha = false;
		if (bFullyOpaque)
		{
			bWriteDepthToAlpha = pShaderAPI->ShouldWriteDepthToDestAlpha();
			bWriteWaterFogToAlpha = fogType == MATERIAL_FOG_LINEAR_BELOW_FOG_Z;
		}

		DECLARE_DYNAMIC_VERTEX_SHADER(EllipsoidClipVertexLit_vs30);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(DOWATERFOG, fogIndex);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(SKINNING, numBones > 0);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(
			LIGHTING_PREVIEW,
			pShaderAPI->GetIntRenderingParameter(INT_RENDERPARM_ENABLE_FIXED_LIGHTING) != 0
		);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(COMPRESSED_VERTS, (int)vertexCompression);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(NUM_LIGHTS, lightState.m_nNumLights);
		SET_DYNAMIC_VERTEX_SHADER(EllipsoidClipVertexLit_vs30);

		DECLARE_DYNAMIC_PIXEL_SHADER(EllipsoidClipVertexLit_ps30);
		SET_DYNAMIC_PIXEL_SHADER_COMBO(NUM_LIGHTS, lightState.m_nNumLights);
		SET_DYNAMIC_PIXEL_SHADER_COMBO(WRITEWATERFOGTODESTALPHA, bWriteWaterFogToAlpha);
		SET_DYNAMIC_PIXEL_SHADER_COMBO(WRITE_DEPTH_TO_DESTALPHA, bWriteDepthToAlpha);
		SET_DYNAMIC_PIXEL_SHADER_COMBO(PIXELFOGTYPE, pShaderAPI->GetPixelFogCombo());
		SET_DYNAMIC_PIXEL_SHADER_COMBO(FLASHLIGHTSHADOWS, bFlashlightShadows);
		SET_DYNAMIC_PIXEL_SHADER(EllipsoidClipVertexLit_ps30);

		float baseTextureTransform[8];
		if (params[BASETEXTURETRANSFORM]->GetType() == MATERIAL_VAR_TYPE_MATRIX)
		{
			const VMatrix& matrix = params[BASETEXTURETRANSFORM]->GetMatrixValue();
			for (int row = 0; row < 2; ++row)
			{
				for (int column = 0; column < 4; ++column)
				{
					baseTextureTransform[row * 4 + column] = matrix[row][column];
				}
			}
		}
		else
		{
			float identity[8] = { 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f };
			memcpy(baseTextureTransform, identity, sizeof(identity));
		}

		pShaderAPI->SetVertexShaderConstant(
			VERTEX_SHADER_SHADER_SPECIFIC_CONST_0,
			baseTextureTransform,
			2
		);

		if (bHasBump)
		{
			float bumpTextureTransform[8];
			if (params[BUMPTRANSFORM]->GetType() == MATERIAL_VAR_TYPE_MATRIX)
			{
				const VMatrix& matrix = params[BUMPTRANSFORM]->GetMatrixValue();
				for (int row = 0; row < 2; ++row)
				{
					for (int column = 0; column < 4; ++column)
					{
						bumpTextureTransform[row * 4 + column] =
							matrix[row][column];
					}
				}
			}
			else
			{
				float identity[8] =
				{
					1.0f, 0.0f, 0.0f, 0.0f,
					0.0f, 1.0f, 0.0f, 0.0f
				};
				memcpy(
					bumpTextureTransform,
					identity,
					sizeof(identity)
				);
			}

			pShaderAPI->SetVertexShaderConstant(
				VERTEX_SHADER_SHADER_SPECIFIC_CONST_2,
				bumpTextureTransform,
				2
			);
		}

		const float* c1 = params[ELLIPSOID_CENTER_1]->GetVecValue();
		const float* a1 = params[ELLIPSOID_ANGLE_1]->GetVecValue();
		const float* s1 = params[ELLIPSOID_SCALE_1]->GetVecValue();
		const float* c2 = params[ELLIPSOID_CENTER_2]->GetVecValue();
		const float* a2 = params[ELLIPSOID_ANGLE_2]->GetVecValue();
		const float* s2 = params[ELLIPSOID_SCALE_2]->GetVecValue();
		const float* c3 = params[ELLIPSOID_CENTER_3]->GetVecValue();
		const float* a3 = params[ELLIPSOID_ANGLE_3]->GetVecValue();
		const float* s3 = params[ELLIPSOID_SCALE_3]->GetVecValue();

		float f0 = SW2ECPack2(SW2ECNormCenter(c1[0]), SW2ECNormCenter(c1[1]));
		float f1 = SW2ECPack2(SW2ECNormCenter(c1[2]), SW2ECNormAngle(a1[0]));
		float f2 = SW2ECPack2(SW2ECNormAngle(a1[1]), SW2ECNormAngle(a1[2]));
		float f3 = SW2ECPack2(SW2ECNormRadius(s1[0]), SW2ECNormRadius(s1[1]));
		float f4 = SW2ECNormRadius(s1[2]);
		float f5 = SW2ECPack2(SW2ECNormCenter(c2[0]), SW2ECNormCenter(c2[1]));
		float f6 = SW2ECPack2(SW2ECNormCenter(c2[2]), SW2ECNormAngle(a2[0]));
		float f7 = SW2ECPack2(SW2ECNormAngle(a2[1]), SW2ECNormAngle(a2[2]));
		float f8 = SW2ECPack2(SW2ECNormRadius(s2[0]), SW2ECNormRadius(s2[1]));
		float f9 = SW2ECNormRadius(s2[2]);
		float f10 = SW2ECPack2(SW2ECNormCenter(c3[0]), SW2ECNormCenter(c3[1]));
		float f11 = SW2ECPack2(SW2ECNormCenter(c3[2]), SW2ECNormAngle(a3[0]));
		float f12 = SW2ECPack2(SW2ECNormAngle(a3[1]), SW2ECNormAngle(a3[2]));
		float f13 = SW2ECPack2(SW2ECNormRadius(s3[0]), SW2ECNormRadius(s3[1]));
		float f14 = SW2ECNormRadius(s3[2]);

		float EP0[4] = { f0, f1, f2, f3 };
		float EP1[4] = { f4, f5, f6, f7 };
		float EP2[4] = { f8, f9, f10, f11 };
		float EP3[4] = { f12, f13, f14, 0.0f };
		pShaderAPI->SetVertexShaderConstant(
			VERTEX_SHADER_SHADER_SPECIFIC_CONST_4, EP0, 1);
		pShaderAPI->SetVertexShaderConstant(
			VERTEX_SHADER_SHADER_SPECIFIC_CONST_5, EP1, 1);
		pShaderAPI->SetVertexShaderConstant(
			VERTEX_SHADER_SHADER_SPECIFIC_CONST_6, EP2, 1);
		pShaderAPI->SetVertexShaderConstant(
			VERTEX_SHADER_SHADER_SPECIFIC_CONST_7, EP3, 1);

		float bloodRange = params[BLOOD_RANGE]->GetFloatValue();
		pShaderAPI->SetPixelShaderConstant(
			PSREG_CONSTANT_03,
			&bloodRange,
			1
		);

		float color[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
		params[COLOR]->GetVecValue(color, 3);
		color[3] = params[ALPHA]->GetFloatValue();
		pShaderAPI->SetPixelShaderConstant(PSREG_DIFFUSE_MODULATION, color, 1);

		if (!bHasFlashlight)
		{
			pShaderAPI->BindStandardTexture(
				SHADER_SAMPLER5,
				TEXTURE_NORMALIZATION_CUBEMAP_SIGNED
			);
		}

		pShaderAPI->SetPixelShaderStateAmbientLightCube(
			PSREG_AMBIENT_CUBE,
			!lightState.m_bAmbientLight
		);
		pShaderAPI->CommitPixelShaderLighting(PSREG_LIGHT_INFO_ARRAY);
		pShaderAPI->SetPixelShaderFogParams(PSREG_FOG_PARAMS);

		float eyePosSpecExponent[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
		pShaderAPI->GetWorldSpaceCameraPosition(eyePosSpecExponent);
		pShaderAPI->SetPixelShaderConstant(
			PSREG_EYEPOS_SPEC_EXPONENT,
			eyePosSpecExponent,
			1
		);

		if (bHasPhong)
		{
			float fresnelRangesSpecBoost[4] = { 1.0f, 0.5f, 1.0f, 1.0f };
			float rimBoost[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
			float specularTint[4] = { 1.0f, 1.0f, 1.0f, 4.0f };

			if (bHasPhongExponentTexture)
			{
				eyePosSpecExponent[3] = -1.0f;
			}
			else
			{
				float exponent = params[PHONGEXPONENT]->GetFloatValue();
				eyePosSpecExponent[3] = exponent > 0.0f ? exponent : 5.0f;
			}

			params[PHONGTINT]->GetVecValue(specularTint, 3);

			if (bHasRimLight)
			{
				specularTint[3] = max(
					params[RIMLIGHTEXPONENT]->GetFloatValue(),
					1.0f
				);
				rimBoost[3] = params[RIMLIGHTBOOST]->GetFloatValue();
			}

			float rimMaskControl[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
			rimMaskControl[0] =
				bHasRimMaskMap
					? params[RIMMASK]->GetFloatValue()
					: 0.0f;

			if (
				specularTint[0] == 0.0f &&
				specularTint[1] == 0.0f &&
				specularTint[2] == 0.0f
			)
			{
				if (bHasPhongTintMap)
				{
					specularTint[0] = -1.0f;
				}
				else
				{
					specularTint[0] = 1.0f;
					specularTint[1] = 1.0f;
					specularTint[2] = 1.0f;
				}
			}

			params[PHONGFRESNELRANGES]->GetVecValue(
				fresnelRangesSpecBoost,
				3
			);
			fresnelRangesSpecBoost[0] =
				(fresnelRangesSpecBoost[1] - fresnelRangesSpecBoost[0]) * 2.0f;
			fresnelRangesSpecBoost[2] =
				(fresnelRangesSpecBoost[2] - fresnelRangesSpecBoost[1]) * 2.0f;
			fresnelRangesSpecBoost[3] =
				params[PHONGBOOST]->GetFloatValue();

			pShaderAPI->SetPixelShaderConstant(
				PSREG_EYEPOS_SPEC_EXPONENT,
				eyePosSpecExponent,
				1
			);
			pShaderAPI->SetPixelShaderConstant(
				PSREG_FRESNEL_SPEC_PARAMS,
				fresnelRangesSpecBoost,
				1
			);
			pShaderAPI->SetPixelShaderConstant(
				PSREG_FLASHLIGHT_POSITION_RIM_BOOST,
				rimBoost,
				1
			);
			pShaderAPI->SetPixelShaderConstant(
				PSREG_SPEC_RIM_PARAMS,
				specularTint,
				1
			);
			pShaderAPI->SetPixelShaderConstant(
				PSREG_FLASHLIGHT_ATTENUATION,
				rimMaskControl,
				1
			);
		}

		if (bHasFlashlight)
		{
			VMatrix worldToTexture;
			float atten[4];
			float pos[4];
			float tweaks[4];
			const FlashlightState_t& flashlightState =
				pShaderAPI->GetFlashlightState(worldToTexture);

			SetFlashLightColorFromState(
				flashlightState,
				pShaderAPI,
				PSREG_FLASHLIGHT_COLOR
			);

			pShader->BindTexture(
				SHADER_SAMPLER6,
				flashlightState.m_pSpotlightTexture,
				flashlightState.m_nSpotlightTextureFrame
			);

			atten[0] = flashlightState.m_fConstantAtten;
			atten[1] = flashlightState.m_fLinearAtten;
			atten[2] = flashlightState.m_fQuadraticAtten;
			atten[3] = flashlightState.m_FarZ;
			pShaderAPI->SetPixelShaderConstant(
				PSREG_FLASHLIGHT_ATTENUATION,
				atten,
				1
			);

			pos[0] = flashlightState.m_vecLightOrigin[0];
			pos[1] = flashlightState.m_vecLightOrigin[1];
			pos[2] = flashlightState.m_vecLightOrigin[2];
			pShaderAPI->SetPixelShaderConstant(
				PSREG_FLASHLIGHT_POSITION_RIM_BOOST,
				pos,
				1
			);

			pShaderAPI->SetPixelShaderConstant(
				PSREG_FLASHLIGHT_TO_WORLD_TEXTURE,
				worldToTexture.Base(),
				4
			);

			tweaks[0] = ShadowFilterFromState(flashlightState);
			tweaks[1] = ShadowAttenFromState(flashlightState);
			pShader->HashShadow2DJitter(
				flashlightState.m_flShadowJitterSeed,
				&tweaks[2],
				&tweaks[3]
			);
			pShaderAPI->SetPixelShaderConstant(
				PSREG_ENVMAP_TINT__SHADOW_TWEAKS,
				tweaks,
				1
			);

			int nWidth;
			int nHeight;
			pShaderAPI->GetBackBufferDimensions(nWidth, nHeight);
			float screenScale[4] =
			{
				(float)nWidth / 32.0f,
				(float)nHeight / 32.0f,
				0.0f,
				0.0f
			};
			pShaderAPI->SetPixelShaderConstant(
				PSREG_FLASHLIGHT_SCREEN_SCALE,
				screenScale,
				1
			);
		}
	}

	pShader->Draw();
}

SHADER_DRAW
{
	bool bHasFlashlight = this->UsingFlashlight(params);
	if (bHasFlashlight)
	{
		DrawWoundVertexLit(
			this,
			params,
			pShaderAPI,
			pShaderShadow,
			false,
			vertexCompression
		);

		if (pShaderShadow)
		{
			this->SetInitialShadowState();
		}
	}

	DrawWoundVertexLit(
		this,
		params,
		pShaderAPI,
		pShaderShadow,
		bHasFlashlight,
		vertexCompression
	);
}

END_SHADER
