//	DYNAMIC: "SKINNING"					"0..1"
//  DYNAMIC: "COMPRESSED_VERTS"			"0..1"

#include "common_vs_fxc.h"

static const bool g_bSkinning = SKINNING ? true : false;

// ============================================================
// 3 个椭球, 每椭球 9 个值 (center 3 + euler 3 + radius 3)
// 每个值归一化到 [0,1), 每 2 个值打包成 1 个 float
// 打包: packed = a + round(b * 2048)
// 解包: b = floor(packed) / 2048, a = frac(packed)
//
// 每个椭球 5 个 float:
//   f0 = pack(c.x, c.y)
//   f1 = pack(c.z, e.x)
//   f2 = pack(e.y, e.z)
//   f3 = pack(r.x, r.y)
//   f4 = r.z
//
// 3 个椭球 = 15 个 float, 放进 4 个 float4, 第 16 个空闲
// ============================================================
const float4 g_EP0 : register( SHADER_SPECIFIC_CONST_0 );
const float4 g_EP1 : register( SHADER_SPECIFIC_CONST_1 );
const float4 g_EP2 : register( SHADER_SPECIFIC_CONST_2 );
const float4 g_EP3 : register( SHADER_SPECIFIC_CONST_3 );

struct VS_INPUT
{
	float4 vPos						: POSITION;
	float2 vBaseTexCoord			: TEXCOORD0;
	float4 vBoneWeights				: BLENDWEIGHT;
	float4 vBoneIndices				: BLENDINDICES;
	float3 vPosFlex					: POSITION1;
};

struct VS_OUTPUT
{
	float4 vProjPos					: POSITION;
	float2 vBaseTexCoord			: TEXCOORD0;
	float3 vWoundData0				: TEXCOORD1;
	float3 vWoundData1				: TEXCOORD2;
	float3 vWoundData2				: TEXCOORD3;
};



#define WOUND_RANGE_CENTER 500.0
#define WOUND_RANGE_ANGLE  6.2831853
#define WOUND_RANGE_RADIUS 100.0
// Replaces the old WoundMode.x deformed-range value.
#define WOUND_DEFORM_SIZE  1.0

// 解包: b = floor(packed) / 2048, a = frac(packed)
void Unpack2( float packed, out float a, out float b )
{
	float k = floor( packed );
	b = k / 2048.0;
	a = packed - k;
}

// 反归一化
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

// ---------- 椭球局部坐标 q = R^T*(p-c)/r ----------
float3 EllipsoidLocal( float3 p, float3 c, float3 e, float3 r )
{
	// e = (pitch, yaw, roll)
	float sp = sin( e.x ), cp = cos( e.x );
	float sy = sin( e.y ), cy = cos( e.y );
	float sr = sin( e.z ), cr = cos( e.z );

	// R = Rz * Ry * Rx 的三列
	float3 col0 = float3( cp * cy, cp * sy, -sp );
	float3 col1 = float3( sp * sr * cy - cr * sy, sp * sr * sy + cr * cy, sr * cp );
	float3 col2 = float3( sp * cr * cy + sr * sy, sp * cr * sy - sr * cy, cr * cp );

	float3 d = p - c;
	return float3( dot( d, col0 ), dot( d, col1 ), dot( d, col2 ) ) / r;
}

// ---------- 局部 -> 世界 p = c + R*(r .* q) ----------
float3 EllipsoidWorld( float3 c, float3 e, float3 r, float3 q )
{
	// e = (pitch, yaw, roll)
	float sp = sin( e.x ), cp = cos( e.x );
	float sy = sin( e.y ), cy = cos( e.y );
	float sr = sin( e.z ), cr = cos( e.z );

	// R 的三行
	float3 row0 = float3( cp * cy, sp * sr * cy - cr * sy, sp * cr * cy + sr * sy );
	float3 row1 = float3( cp * sy, sp * sr * sy + cr * cy, sp * cr * sy - sr * cy );
	float3 row2 = float3( -sp, sr * cp, cr * cp );

	float3 rq = r * q;
	return c + float3( dot( row0, rq ), dot( row1, rq ), dot( row2, rq ) );
}

// ---------- 处理单个椭球 ----------
// woundData = (q.yz, dist), 返回值 = 变形后的模型空间位置
float3 ProcessEllipsoid( float3 p, float3 c, float3 e, float3 r,
                         out float3 woundData, out float dist )
{
	float3 q = EllipsoidLocal( p, c, e, r );
	dist = length( q );
	woundData = float3( q.yz, dist );

	// 变形: x 推负, 归一化, 再变回模型空间
	q.x = -abs( q.x );
	float3 qn = q / max( dist, 1e-6 );
	return EllipsoidWorld( c, e, r, qn );
}

VS_OUTPUT main( const VS_INPUT v )
{
	VS_OUTPUT o = ( VS_OUTPUT )0;

	float3 modelPos = v.vPos.xyz;

	// ---- 取出 15 个 float ----
	float f0  = g_EP0.x;
	float f1  = g_EP0.y;
	float f2  = g_EP0.z;
	float f3  = g_EP0.w;
	float f4  = g_EP1.x;
	float f5  = g_EP1.y;
	float f6  = g_EP1.z;
	float f7  = g_EP1.w;
	float f8  = g_EP2.x;
	float f9  = g_EP2.y;
	float f10 = g_EP2.z;
	float f11 = g_EP2.w;
	float f12 = g_EP3.x;
	float f13 = g_EP3.y;
	float f14 = g_EP3.z;

	// ---- 解包 ----
	float a, b;

	// 椭球 0
	Unpack2( f0, a, b ); float3 c0 = float3( DenormCenter(a), DenormCenter(b), 0 );
	Unpack2( f1, a, b ); c0.z = DenormCenter(a); float3 e0 = float3( DenormAngle(b), 0, 0 );
	Unpack2( f2, a, b ); e0.y = DenormAngle(a); e0.z = DenormAngle(b);
	Unpack2( f3, a, b ); float3 r0 = float3( DenormRadius(a), DenormRadius(b), 0 );
	r0.z = DenormRadius( f4 );

	// 椭球 1
	Unpack2( f5, a, b ); float3 c1 = float3( DenormCenter(a), DenormCenter(b), 0 );
	Unpack2( f6, a, b ); c1.z = DenormCenter(a); float3 e1 = float3( DenormAngle(b), 0, 0 );
	Unpack2( f7, a, b ); e1.y = DenormAngle(a); e1.z = DenormAngle(b);
	Unpack2( f8, a, b ); float3 r1 = float3( DenormRadius(a), DenormRadius(b), 0 );
	r1.z = DenormRadius( f9 );

	// 椭球 2
	Unpack2( f10, a, b ); float3 c2 = float3( DenormCenter(a), DenormCenter(b), 0 );
	Unpack2( f11, a, b ); c2.z = DenormCenter(a); float3 e2 = float3( DenormAngle(b), 0, 0 );
	Unpack2( f12, a, b ); e2.y = DenormAngle(a); e2.z = DenormAngle(b);
	Unpack2( f13, a, b ); float3 r2 = float3( DenormRadius(a), DenormRadius(b), 0 );
	r2.z = DenormRadius( f14 );

	// ---- 三个椭球分别处理 ----
	float3 wd0, wd1, wd2;
	float  d0, d1, d2;
	float3 dpos0 = ProcessEllipsoid( modelPos, c0, e0, r0, wd0, d0 );
	float3 dpos1 = ProcessEllipsoid( modelPos, c1, e1, r1, wd1, d1 );
	float3 dpos2 = ProcessEllipsoid( modelPos, c2, e2, r2, wd2, d2 );

	o.vWoundData0 = wd0;
	o.vWoundData1 = wd1;
	o.vWoundData2 = wd2;

	// ---- 变形: 选最近椭球, 无分支 ----
	float3 selectedDpos = dpos0;
	float  bestDist     = d0;

	float use1 = step( d1, bestDist );
	selectedDpos = lerp( selectedDpos, dpos1, use1 );
	bestDist     = min( bestDist, d1 );

	float use2 = step( d2, bestDist );
	selectedDpos = lerp( selectedDpos, dpos2, use2 );
	bestDist     = min( bestDist, d2 );

	// 归一化空间里 dist=1 是椭球表面, 所以变形半径硬编码为 1.0
	float deformAmount = step( bestDist, WOUND_DEFORM_SIZE );
	float3 finalModelPos = lerp( modelPos, selectedDpos, deformAmount );
	ApplyMorph( v.vPosFlex, finalModelPos );

	// ---- 蒙皮 ----
	float3 worldPos;
	SkinPosition(
		g_bSkinning,
		float4( finalModelPos, 1 ),
		v.vBoneWeights, v.vBoneIndices,
		worldPos );

	o.vProjPos = mul( float4( worldPos, 1 ), cViewProj );
	o.vBaseTexCoord = v.vBaseTexCoord;

	return o;
}
