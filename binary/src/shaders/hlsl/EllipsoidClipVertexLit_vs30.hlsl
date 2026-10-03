//	STATIC: "BUMPMAP"					"0..1"
//	DYNAMIC: "COMPRESSED_VERTS"			"0..1"
//	DYNAMIC: "DOWATERFOG"				"0..1"
//	DYNAMIC: "SKINNING"					"0..1"
//	DYNAMIC: "LIGHTING_PREVIEW"			"0..1"
//	DYNAMIC: "NUM_LIGHTS"				"0..4"

#include "common_vs_fxc.h"

static const bool g_bSkinning = SKINNING ? true : false;
static const int g_FogType = DOWATERFOG;

const float4 cBaseTexCoordTransform[2] : register( SHADER_SPECIFIC_CONST_0 );
#if BUMPMAP
const float4 cBumpTexCoordTransform[2] : register( SHADER_SPECIFIC_CONST_2 );
#endif
const float4 g_EP0 : register( SHADER_SPECIFIC_CONST_4 );
const float4 g_EP1 : register( SHADER_SPECIFIC_CONST_5 );
const float4 g_EP2 : register( SHADER_SPECIFIC_CONST_6 );
const float4 g_EP3 : register( SHADER_SPECIFIC_CONST_7 );

struct VS_INPUT
{
	float4 vPos			: POSITION;
	float4 vBoneWeights	: BLENDWEIGHT;
	float4 vBoneIndices	: BLENDINDICES;
	float4 vNormal		: NORMAL;
	float4 vTexCoord0	: TEXCOORD0;
	float3 vPosFlex		: POSITION1;
	float3 vNormalFlex	: NORMAL1;
#if BUMPMAP
	float4 vUserData	: TANGENT;
#endif
};

struct VS_OUTPUT
{
	float4 projPosSetup		: POSITION;
	float2 baseTexCoord		: TEXCOORD0;
	float4 lightAtten		: TEXCOORD1;
	float3 worldNormal		: TEXCOORD2;
	float3 worldPos			: TEXCOORD3;
	float4 worldTangent		: TEXCOORD4;
	float4 woundData01		: TEXCOORD5;
	float4 woundData2		: TEXCOORD6;
	float4 woundTail		: TEXCOORD7;
};

#define WOUND_RANGE_CENTER 500.0
#define WOUND_RANGE_ANGLE  6.2831853
#define WOUND_RANGE_RADIUS 100.0

void Unpack2( float packed, out float a, out float b )
{
	float k = floor( packed );
	b = k / 2048.0;
	a = packed - k;
}

float DenormCenter( float v )
{
	return v * ( 2.0 * WOUND_RANGE_CENTER ) - WOUND_RANGE_CENTER;
}

float DenormAngle( float v )
{
	return v * WOUND_RANGE_ANGLE;
}

float DenormRadius( float v )
{
	return v * WOUND_RANGE_RADIUS;
}

float3 EllipsoidLocal( float3 p, float3 c, float3 e, float3 r )
{
	float sp = sin( e.x ), cp = cos( e.x );
	float sy = sin( e.y ), cy = cos( e.y );
	float sr = sin( e.z ), cr = cos( e.z );

	float3 col0 = float3( cp * cy, cp * sy, -sp );
	float3 col1 = float3( sp * sr * cy - cr * sy, sp * sr * sy + cr * cy, sr * cp );
	float3 col2 = float3( sp * cr * cy + sr * sy, sp * cr * sy - sr * cy, cr * cp );

	float3 d = p - c;
	return float3( dot( d, col0 ), dot( d, col1 ), dot( d, col2 ) ) / r;
}

void ProcessEllipsoid(
	float3 p,
	float3 c,
	float3 e,
	float3 r,
	out float3 woundData,
	out float dist
)
{
	float3 q = EllipsoidLocal( p, c, e, r );
	dist = length( q );
	woundData = float3( q.yz, dist );
}

VS_OUTPUT main( const VS_INPUT v )
{
	VS_OUTPUT o = ( VS_OUTPUT )0;
	float3 modelPos = v.vPos.xyz;
	float3 vNormal;
	float3 worldNormal;
	float3 worldPos;
	float3 morphedPos = modelPos;
	float3 morphedNormal;

#if BUMPMAP
	float4 vTangent;
	DecompressVertex_NormalTangent( v.vNormal, v.vUserData, vNormal, vTangent );
	morphedNormal = vNormal;
	ApplyMorph( v.vPosFlex, v.vNormalFlex, morphedPos, morphedNormal, vTangent.xyz );
	morphedNormal = normalize( morphedNormal );
	float3 worldTangentS;
	float3 worldTangentT;
	SkinPositionNormalAndTangentSpace(
		g_bSkinning, float4( morphedPos, 1 ), morphedNormal, vTangent,
		v.vBoneWeights, v.vBoneIndices,
		worldPos, worldNormal, worldTangentS, worldTangentT
	);
	worldNormal = normalize( worldNormal );
	worldTangentS = normalize( worldTangentS );
	worldTangentT = normalize( worldTangentT );
	o.worldTangent = float4( worldTangentS, vTangent.w );
#else
	DecompressVertex_Normal( v.vNormal, vNormal );
	morphedNormal = vNormal;
	ApplyMorph( v.vPosFlex, v.vNormalFlex, morphedPos, morphedNormal );
	morphedNormal = normalize( morphedNormal );
	SkinPositionAndNormal(
		g_bSkinning, float4( morphedPos, 1 ), morphedNormal,
		v.vBoneWeights, v.vBoneIndices,
		worldPos, worldNormal
	);
	worldNormal = normalize( worldNormal );
	o.worldTangent = float4( 1.0f, 0.0f, 0.0f, 1.0f );
#endif

	float f0 = g_EP0.x, f1 = g_EP0.y, f2 = g_EP0.z, f3 = g_EP0.w;
	float f4 = g_EP1.x, f5 = g_EP1.y, f6 = g_EP1.z, f7 = g_EP1.w;
	float f8 = g_EP2.x, f9 = g_EP2.y, f10 = g_EP2.z, f11 = g_EP2.w;
	float f12 = g_EP3.x, f13 = g_EP3.y, f14 = g_EP3.z;
	float a, b;

	Unpack2( f0, a, b ); float3 c0 = float3( DenormCenter(a), DenormCenter(b), 0 );
	Unpack2( f1, a, b ); c0.z = DenormCenter(a); float3 e0 = float3( DenormAngle(b), 0, 0 );
	Unpack2( f2, a, b ); e0.y = DenormAngle(a); e0.z = DenormAngle(b);
	Unpack2( f3, a, b ); float3 r0 = float3( DenormRadius(a), DenormRadius(b), 0 );
	r0.z = DenormRadius( f4 );

	Unpack2( f5, a, b ); float3 c1 = float3( DenormCenter(a), DenormCenter(b), 0 );
	Unpack2( f6, a, b ); c1.z = DenormCenter(a); float3 e1 = float3( DenormAngle(b), 0, 0 );
	Unpack2( f7, a, b ); e1.y = DenormAngle(a); e1.z = DenormAngle(b);
	Unpack2( f8, a, b ); float3 r1 = float3( DenormRadius(a), DenormRadius(b), 0 );
	r1.z = DenormRadius( f9 );

	Unpack2( f10, a, b ); float3 c2 = float3( DenormCenter(a), DenormCenter(b), 0 );
	Unpack2( f11, a, b ); c2.z = DenormCenter(a); float3 e2 = float3( DenormAngle(b), 0, 0 );
	Unpack2( f12, a, b ); e2.y = DenormAngle(a); e2.z = DenormAngle(b);
	Unpack2( f13, a, b ); float3 r2 = float3( DenormRadius(a), DenormRadius(b), 0 );
	r2.z = DenormRadius( f14 );

	float3 wd0, wd1, wd2;
	float d0, d1, d2;
	ProcessEllipsoid( modelPos, c0, e0, r0, wd0, d0 );
	ProcessEllipsoid( modelPos, c1, e1, r1, wd1, d1 );
	ProcessEllipsoid( modelPos, c2, e2, r2, wd2, d2 );

	float4 vProjPos = mul( float4( worldPos, 1 ), cViewProj );
	o.projPosSetup = vProjPos;
	o.baseTexCoord.x = dot( v.vTexCoord0, cBaseTexCoordTransform[0] );
	o.baseTexCoord.y = dot( v.vTexCoord0, cBaseTexCoordTransform[1] );
	o.worldNormal = worldNormal;
	o.worldPos = worldPos;

	o.lightAtten.xyz = float3( 0.0f, 0.0f, 0.0f );
#if ( NUM_LIGHTS > 0 )
	o.lightAtten.x = GetVertexAttenForLight( worldPos, 0, false );
#endif
#if ( NUM_LIGHTS > 1 )
	o.lightAtten.y = GetVertexAttenForLight( worldPos, 1, false );
#endif
#if ( NUM_LIGHTS > 2 )
	o.lightAtten.z = GetVertexAttenForLight( worldPos, 2, false );
#endif
#if ( NUM_LIGHTS > 3 )
	o.lightAtten.w = GetVertexAttenForLight( worldPos, 3, false );
#endif

	float2 bumpTexCoord = o.baseTexCoord;
#if BUMPMAP
	bumpTexCoord.x = dot( v.vTexCoord0, cBumpTexCoordTransform[0] );
	bumpTexCoord.y = dot( v.vTexCoord0, cBumpTexCoordTransform[1] );
#endif

	o.woundData01 = float4( wd0.xy, wd1.xy );
	o.woundData2 = float4( wd2.xy, wd0.z, wd1.z );
	o.woundTail = float4( wd2.z, bumpTexCoord.x, bumpTexCoord.y, vProjPos.z );

	return o;
}
