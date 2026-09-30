#include "BaseVSShader.h"

#include "shaders/inc/VertexDeformation_vs30.inc"
#include "shaders/inc/VertexDeformation_ps30.inc"

#include <istudiorender.h>
#include <algorithm>
using std::min;
using std::max;

// ============================================================
// 归一化 + 打包
// 中心: [-500, 500] -> [0, 1]
// 角度: [0, 2π]     -> [0, 1]
// 半径: [0, 100]    -> [0, 1]
// 打包: packed = a + round(b * 2048)
// ============================================================

#define WOUND_RANGE_CENTER 500.0f
#define WOUND_RANGE_ANGLE  6.2831853f
#define WOUND_RANGE_RADIUS 100.0f

// 归一化: 把原始值压到 [0, 1)
static inline float NormCenter( float v )
{
	float n = ( v + WOUND_RANGE_CENTER ) / ( 2.0f * WOUND_RANGE_CENTER );
	return min( max( n, 0.0f ), 0.9999f );
}

static inline float NormAngle( float v )
{
	// 先把角度包到 [0, 2π)
	float a = fmod( v, WOUND_RANGE_ANGLE );
	if ( a < 0.0f )
		a += WOUND_RANGE_ANGLE;

	float n = a / WOUND_RANGE_ANGLE;
	return min( n, 0.9999f );
}

static inline float NormRadius( float v )
{
	float n = v / WOUND_RANGE_RADIUS;
	return min( max( n, 0.0f ), 0.9999f );
}

// 打包: packed = a + round(b * 2048)
static inline float Pack2( float a, float b )
{
	float k = floor( b * 2048.0f + 0.5f );
	return a + k;
}


BEGIN_VS_SHADER(VertexDeformation, "Help for VertexDeformation")

BEGIN_SHADER_PARAMS
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

	SHADER_PARAM(DEFORM_TEXTURE, SHADER_PARAM_TYPE_TEXTURE, "models/flesh", "Deformed texture")
	SHADER_PARAM(PROJECT_TEXTURE, SHADER_PARAM_TYPE_TEXTURE, "models/flesh", "Projected texture")
END_SHADER_PARAMS


SHADER_INIT_PARAMS()
{
	SET_FLAGS2(MATERIAL_VAR2_SUPPORTS_HW_SKINNING);

	if (!params[ELLIPSOID_CENTER_1]->IsDefined())
	{
		params[ELLIPSOID_CENTER_1]->SetVecValue(0.0, 0.0, 0.0);
	}

	if (!params[ELLIPSOID_ANGLE_1]->IsDefined())
	{
		params[ELLIPSOID_ANGLE_1]->SetVecValue(0.0, 0.0, 0.0);
	}

	if (!params[ELLIPSOID_SCALE_1]->IsDefined())
	{
		params[ELLIPSOID_SCALE_1]->SetVecValue(0.0, 0.0, 0.0);
	}

	if (!params[ELLIPSOID_CENTER_2]->IsDefined())
	{
		params[ELLIPSOID_CENTER_2]->SetVecValue(0.0, 0.0, 0.0);
	}

	if (!params[ELLIPSOID_ANGLE_2]->IsDefined())
	{
		params[ELLIPSOID_ANGLE_2]->SetVecValue(0.0, 0.0, 0.0);
	}

	if (!params[ELLIPSOID_SCALE_2]->IsDefined())
	{
		params[ELLIPSOID_SCALE_2]->SetVecValue(0.0, 0.0, 0.0);
	}


	if (!params[ELLIPSOID_CENTER_3]->IsDefined())
	{
		params[ELLIPSOID_CENTER_3]->SetVecValue(0.0, 0.0, 0.0);
	}

	if (!params[ELLIPSOID_ANGLE_3]->IsDefined())
	{
		params[ELLIPSOID_ANGLE_3]->SetVecValue(0.0, 0.0, 0.0);
	}

	if (!params[ELLIPSOID_SCALE_3]->IsDefined())
	{
		params[ELLIPSOID_SCALE_3]->SetVecValue(0.0, 0.0, 0.0);
	}

	if (!params[BLOOD_RANGE]->IsDefined())
	{
		params[BLOOD_RANGE]->SetFloatValue(0.5f);
	}
}

SHADER_FALLBACK
{
	return 0;
}


SHADER_INIT
{
	LoadTexture(BASETEXTURE);

	if (params[DEFORM_TEXTURE]->IsDefined())
	{
		LoadTexture(DEFORM_TEXTURE);
	}

	if (params[PROJECT_TEXTURE]->IsDefined())
	{
		LoadTexture(PROJECT_TEXTURE);
	}

}

SHADER_DRAW
{
	SHADOW_STATE
	{
		pShaderShadow->EnableTexture(SHADER_SAMPLER0, true);
		pShaderShadow->EnableTexture(SHADER_SAMPLER1, true);
		pShaderShadow->EnableTexture(SHADER_SAMPLER2, true);

		int fmt = VERTEX_POSITION | VERTEX_FORMAT_COMPRESSED;
		pShaderShadow->VertexShaderVertexFormat(fmt, 1, 0, 4);
		
		DECLARE_STATIC_VERTEX_SHADER(VertexDeformation_vs30);
		SET_STATIC_VERTEX_SHADER(VertexDeformation_vs30);

		DECLARE_STATIC_PIXEL_SHADER(VertexDeformation_ps30);
		SET_STATIC_PIXEL_SHADER(VertexDeformation_ps30);

		DefaultFog();
	}
	DYNAMIC_STATE
	{
		BindTexture(SHADER_SAMPLER0, BASETEXTURE, FRAME);
		BindTexture(SHADER_SAMPLER1, DEFORM_TEXTURE);
		BindTexture(SHADER_SAMPLER2, PROJECT_TEXTURE);

		// ---- 取 3 个椭球的原始参数 ----
		const float* c1 = params[ELLIPSOID_CENTER_1]->GetVecValue();
		const float* a1 = params[ELLIPSOID_ANGLE_1]->GetVecValue();
		const float* s1 = params[ELLIPSOID_SCALE_1]->GetVecValue();
		const float* c2 = params[ELLIPSOID_CENTER_2]->GetVecValue();
		const float* a2 = params[ELLIPSOID_ANGLE_2]->GetVecValue();
		const float* s2 = params[ELLIPSOID_SCALE_2]->GetVecValue();
		const float* c3 = params[ELLIPSOID_CENTER_3]->GetVecValue();
		const float* a3 = params[ELLIPSOID_ANGLE_3]->GetVecValue();
		const float* s3 = params[ELLIPSOID_SCALE_3]->GetVecValue();

		// ---- 椭球 0: 5 个 float ----
		float f0 = Pack2( NormCenter(c1[0]), NormCenter(c1[1]) );
		float f1 = Pack2( NormCenter(c1[2]), NormAngle (a1[0]) );
		float f2 = Pack2( NormAngle (a1[1]), NormAngle (a1[2]) );
		float f3 = Pack2( NormRadius(s1[0]), NormRadius(s1[1]) );
		float f4 = NormRadius( s1[2] );

		// ---- 椭球 1: 5 个 float ----
		float f5 = Pack2( NormCenter(c2[0]), NormCenter(c2[1]) );
		float f6 = Pack2( NormCenter(c2[2]), NormAngle (a2[0]) );
		float f7 = Pack2( NormAngle (a2[1]), NormAngle (a2[2]) );
		float f8 = Pack2( NormRadius(s2[0]), NormRadius(s2[1]) );
		float f9 = NormRadius( s2[2] );

		// ---- 椭球 2: 5 个 float ----
		float f10 = Pack2( NormCenter(c3[0]), NormCenter(c3[1]) );
		float f11 = Pack2( NormCenter(c3[2]), NormAngle (a3[0]) );
		float f12 = Pack2( NormAngle (a3[1]), NormAngle (a3[2]) );
		float f13 = Pack2( NormRadius(s3[0]), NormRadius(s3[1]) );
		float f14 = NormRadius( s3[2] );

		// ---- 打包进 4 个 float4 ----
		float EP0[4] = { f0,  f1,  f2,  f3  };
		float EP1[4] = { f4,  f5,  f6,  f7  };
		float EP2[4] = { f8,  f9,  f10, f11 };
		float EP3[4] = { f12, f13, f14, 0.0f };

		pShaderAPI->SetVertexShaderConstant(
			VERTEX_SHADER_SHADER_SPECIFIC_CONST_0, EP0, 1 );
		pShaderAPI->SetVertexShaderConstant(
			VERTEX_SHADER_SHADER_SPECIFIC_CONST_1, EP1, 1 );
		pShaderAPI->SetVertexShaderConstant(
			VERTEX_SHADER_SHADER_SPECIFIC_CONST_2, EP2, 1 );
		pShaderAPI->SetVertexShaderConstant(
			VERTEX_SHADER_SHADER_SPECIFIC_CONST_3, EP3, 1 );

		float bloodRange = params[BLOOD_RANGE]->GetFloatValue();
		pShaderAPI->SetPixelShaderConstant( 0, &bloodRange, 1 );

		DECLARE_DYNAMIC_VERTEX_SHADER( VertexDeformation_vs30 );
		SET_DYNAMIC_VERTEX_SHADER_COMBO( SKINNING, pShaderAPI->GetCurrentNumBones() > 0 );
		SET_DYNAMIC_VERTEX_SHADER_COMBO( COMPRESSED_VERTS, (int)vertexCompression );
		SET_DYNAMIC_VERTEX_SHADER( VertexDeformation_vs30 );
	}

	Draw();
}
END_SHADER
