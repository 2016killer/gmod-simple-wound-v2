#include "common_ps_fxc.h"

// Replaces the old WoundMode.x deformed-range value.
#define WOUND_DEFORM_SIZE       1.0
// Replaces the old WoundMode.z alpha-blend toggle.
#define WOUND_USE_PROJECT_ALPHA 0

sampler BaseTextureSampler     : register( s0 );
sampler DeformedTextureSampler : register( s1 );
sampler ProjTextureSampler     : register( s2 );

const float g_BloodRange : register( c0 );

struct PS_INPUT
{
	float2 vBaseTexCoord : TEXCOORD0;
	float3 vWoundData0   : TEXCOORD1;
	float3 vWoundData1   : TEXCOORD2;
	float3 vWoundData2   : TEXCOORD3;
};

// 单个椭球的投影贡献
void AccumProjected( float3 woundData, out float3 rgb, out float weight, out float deform )
{
	float2 uv   = woundData.xy;
	float  dist = woundData.z;

	float4 projColor = tex2D( ProjTextureSampler, uv );

	float distFactor = 1 - smoothstep( WOUND_DEFORM_SIZE,
	                                    WOUND_DEFORM_SIZE + g_BloodRange,
	                                    dist );
	float alphaFactor = WOUND_USE_PROJECT_ALPHA ? projColor.a : 1.0;

	weight = distFactor * alphaFactor;
	rgb    = weight * projColor.rgb;

	deform = step( dist, WOUND_DEFORM_SIZE );
}

float4 main( PS_INPUT i ) : COLOR
{
	float4 baseColor = tex2D( BaseTextureSampler, i.vBaseTexCoord );

	// ---- 三个椭球投影加权混合 ----
	float3 rgb0, rgb1, rgb2;
	float  w0, w1, w2;
	float  d0, d1, d2;

	AccumProjected( i.vWoundData0, rgb0, w0, d0 );
	AccumProjected( i.vWoundData1, rgb1, w1, d1 );
	AccumProjected( i.vWoundData2, rgb2, w2, d2 );

	float totalW = saturate( w0 + w1 + w2 );
	float safeW  = max( totalW, 1e-6 );
	float3 projColor = ( rgb0 + rgb1 + rgb2 ) / safeW;

	baseColor.rgb = lerp( baseColor.rgb, projColor, totalW );

	// ---- 变形纹理: 任意一个椭球触发就应用 ----
	float deformFactor = max( max( d0, d1 ), d2 );
	float4 deformedColor = tex2D( DeformedTextureSampler, i.vBaseTexCoord );
	baseColor = lerp( baseColor, deformedColor, deformFactor );

	return baseColor;
}
