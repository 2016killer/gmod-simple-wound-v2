#include "common_ps_fxc.h"

#define WOUND_CLIP_SIZE         1.0
#define WOUND_USE_PROJECT_ALPHA 0

sampler BaseTextureSampler : register( s0 );
sampler ProjTextureSampler : register( s1 );

const float g_BloodRange : register( c0 );

struct PS_INPUT
{
	float2 vBaseTexCoord : TEXCOORD0;
	float3 vWoundData0   : TEXCOORD1;
	float3 vWoundData1   : TEXCOORD2;
	float3 vWoundData2   : TEXCOORD3;
};

void AccumProjected( float3 woundData, out float3 rgb, out float weight )
{
	float2 uv = woundData.xy;
	float dist = woundData.z;

	float4 projColor = tex2D( ProjTextureSampler, uv );

	float distFactor = 1 - smoothstep(
		WOUND_CLIP_SIZE,
		WOUND_CLIP_SIZE + g_BloodRange,
		dist
	);
	float alphaFactor = WOUND_USE_PROJECT_ALPHA ? projColor.a : 1.0;

	weight = distFactor * alphaFactor;
	rgb = weight * projColor.rgb;
}

float4 main( PS_INPUT i ) : COLOR
{
	float minDist = min( min( i.vWoundData0.z, i.vWoundData1.z ), i.vWoundData2.z );

	clip( minDist - WOUND_CLIP_SIZE );

	float3 rgb0, rgb1, rgb2;
	float w0, w1, w2;

	AccumProjected( i.vWoundData0, rgb0, w0 );
	AccumProjected( i.vWoundData1, rgb1, w1 );
	AccumProjected( i.vWoundData2, rgb2, w2 );

	float totalW = saturate( w0 + w1 + w2 );
	float safeW = max( totalW, 1e-6 );
	float3 projColor = ( rgb0 + rgb1 + rgb2 ) / safeW;

	float4 baseColor = tex2D( BaseTextureSampler, i.vBaseTexCoord );
	baseColor.rgb = lerp( baseColor.rgb, projColor, totalW );

	return baseColor;
}
