#include "BaseVSShader.h"

#include "shaders/inc/EllipsoidClip_vs30.inc"
#include "shaders/inc/EllipsoidClip_ps30.inc"

#include <istudiorender.h>
#include <algorithm>
using std::min;
using std::max;

#define WOUND_RANGE_CENTER 500.0f
#define WOUND_RANGE_ANGLE  6.2831853f
#define WOUND_RANGE_RADIUS 100.0f

static inline float EllipsoidClipNormCenter( float v )
{
	float n = ( v + WOUND_RANGE_CENTER ) / ( 2.0f * WOUND_RANGE_CENTER );
	return min( max( n, 0.0f ), 0.9999f );
}

static inline float EllipsoidClipNormAngle( float v )
{
	float a = fmod( v, WOUND_RANGE_ANGLE );
	if ( a < 0.0f )
		a += WOUND_RANGE_ANGLE;

	float n = a / WOUND_RANGE_ANGLE;
	return min( n, 0.9999f );
}

static inline float EllipsoidClipNormRadius( float v )
{
	float n = v / WOUND_RANGE_RADIUS;
	return min( max( n, 0.0f ), 0.9999f );
}

static inline float EllipsoidClipPack2( float a, float b )
{
	float k = floor( b * 2048.0f + 0.5f );
	return a + k;
}

BEGIN_VS_SHADER(EllipsoidClip, "Help for EllipsoidClip")

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
	SHADER_PARAM(PROJECT_TEXTURE, SHADER_PARAM_TYPE_TEXTURE, "models/flesh", "Projected texture")
END_SHADER_PARAMS

SHADER_INIT_PARAMS()
{
	SET_FLAGS2(MATERIAL_VAR2_SUPPORTS_HW_SKINNING);

	if ( !params[BLOOD_RANGE]->IsDefined() )
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

	if ( params[PROJECT_TEXTURE]->IsDefined() )
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

		int fmt = VERTEX_POSITION | VERTEX_FORMAT_COMPRESSED;
		pShaderShadow->VertexShaderVertexFormat(fmt, 1, 0, 4);

		DECLARE_STATIC_VERTEX_SHADER(EllipsoidClip_vs30);
		SET_STATIC_VERTEX_SHADER(EllipsoidClip_vs30);

		DECLARE_STATIC_PIXEL_SHADER(EllipsoidClip_ps30);
		SET_STATIC_PIXEL_SHADER(EllipsoidClip_ps30);

		DefaultFog();
	}
	DYNAMIC_STATE
	{
		BindTexture(SHADER_SAMPLER0, BASETEXTURE, FRAME);
		BindTexture(SHADER_SAMPLER1, PROJECT_TEXTURE);

		const float* c1 = params[ELLIPSOID_CENTER_1]->GetVecValue();
		const float* a1 = params[ELLIPSOID_ANGLE_1]->GetVecValue();
		const float* s1 = params[ELLIPSOID_SCALE_1]->GetVecValue();
		const float* c2 = params[ELLIPSOID_CENTER_2]->GetVecValue();
		const float* a2 = params[ELLIPSOID_ANGLE_2]->GetVecValue();
		const float* s2 = params[ELLIPSOID_SCALE_2]->GetVecValue();
		const float* c3 = params[ELLIPSOID_CENTER_3]->GetVecValue();
		const float* a3 = params[ELLIPSOID_ANGLE_3]->GetVecValue();
		const float* s3 = params[ELLIPSOID_SCALE_3]->GetVecValue();

		float f0 = EllipsoidClipPack2( EllipsoidClipNormCenter(c1[0]), EllipsoidClipNormCenter(c1[1]) );
		float f1 = EllipsoidClipPack2( EllipsoidClipNormCenter(c1[2]), EllipsoidClipNormAngle (a1[0]) );
		float f2 = EllipsoidClipPack2( EllipsoidClipNormAngle (a1[1]), EllipsoidClipNormAngle (a1[2]) );
		float f3 = EllipsoidClipPack2( EllipsoidClipNormRadius(s1[0]), EllipsoidClipNormRadius(s1[1]) );
		float f4 = EllipsoidClipNormRadius( s1[2] );

		float f5 = EllipsoidClipPack2( EllipsoidClipNormCenter(c2[0]), EllipsoidClipNormCenter(c2[1]) );
		float f6 = EllipsoidClipPack2( EllipsoidClipNormCenter(c2[2]), EllipsoidClipNormAngle (a2[0]) );
		float f7 = EllipsoidClipPack2( EllipsoidClipNormAngle (a2[1]), EllipsoidClipNormAngle (a2[2]) );
		float f8 = EllipsoidClipPack2( EllipsoidClipNormRadius(s2[0]), EllipsoidClipNormRadius(s2[1]) );
		float f9 = EllipsoidClipNormRadius( s2[2] );

		float f10 = EllipsoidClipPack2( EllipsoidClipNormCenter(c3[0]), EllipsoidClipNormCenter(c3[1]) );
		float f11 = EllipsoidClipPack2( EllipsoidClipNormCenter(c3[2]), EllipsoidClipNormAngle (a3[0]) );
		float f12 = EllipsoidClipPack2( EllipsoidClipNormAngle (a3[1]), EllipsoidClipNormAngle (a3[2]) );
		float f13 = EllipsoidClipPack2( EllipsoidClipNormRadius(s3[0]), EllipsoidClipNormRadius(s3[1]) );
		float f14 = EllipsoidClipNormRadius( s3[2] );

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

		DECLARE_DYNAMIC_VERTEX_SHADER( EllipsoidClip_vs30 );
		SET_DYNAMIC_VERTEX_SHADER_COMBO( SKINNING, pShaderAPI->GetCurrentNumBones() > 0 );
		SET_DYNAMIC_VERTEX_SHADER_COMBO( COMPRESSED_VERTS, (int)vertexCompression );
		SET_DYNAMIC_VERTEX_SHADER( EllipsoidClip_vs30 );
	}

	Draw();
}
END_SHADER
