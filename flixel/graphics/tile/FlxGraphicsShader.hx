package flixel.graphics.tile;

import openfl.display.GraphicsShader;

class FlxGraphicsShader extends GraphicsShader
{
	@:glVertexDontOverride
	@:glFragmentDontOverride
	@:glVertexHeader("attribute float openfl_Alpha;
attribute vec4 openfl_ColorMultiplier;
attribute vec4 openfl_ColorOffset;
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;

varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform mat4 openfl_Matrix;
uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;

attribute float alpha;
attribute vec4 colorMultiplier;
attribute vec4 colorOffset;

uniform bool hasTransform;
uniform bool hasColorTransform;")

	@:glVertexBody("openfl_TextureCoordv = openfl_TextureCoord;

if (hasColorTransform) {
	openfl_Alphav = openfl_Alpha * colorMultiplier.a;
	if (openfl_HasColorTransform) {
		openfl_ColorOffsetv = (openfl_ColorOffset / 255.0) * vec4(colorMultiplier.rgb, 1.0) + (colorOffset / 255.0);
		openfl_ColorMultiplierv = vec4(openfl_ColorMultiplier.rgb * colorMultiplier.rgb, 1.0);
	}
	else {
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = vec4(colorMultiplier.rgb, 1.0);
	}
}
else {
	if (hasTransform) openfl_Alphav = openfl_Alpha * alpha;
	else openfl_Alphav = openfl_Alpha;

	if (openfl_HasColorTransform) {
		openfl_ColorOffsetv = (openfl_ColorOffset + colorOffset) / 255.0;
		openfl_ColorMultiplierv = vec4(openfl_ColorMultiplier.rgb, 1.0);
	}
	else {
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = vec4(1.0);
	}
}")

	@:glVertexSource("#pragma header
void main(void) {
	#pragma body
	gl_Position = openfl_Matrix * openfl_Position;
}")

	@:glFragmentHeader("varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;
uniform sampler2D bitmap;

uniform bool hasTransform;
uniform bool hasColorTransform;

uniform vec4 _camSize;

void apply_flixel_transform(inout vec4 color) {
	#if !defined(NO_GUARD_APPLY_FLIXEL_TRANSFORM)
	if (openfl_Alphav == 0.0 || color.a == 0.0) {
		color = vec4(0.0);
		return;
	}
	#endif

	color.rgb /= color.a;

	color = clamp(color * openfl_ColorMultiplierv + openfl_ColorOffsetv, 0.0, 1.0);
	color.a *= openfl_Alphav;

	color.rgb *= color.a;
}
vec4 applyFlixelEffects(vec4 color) {
	apply_flixel_transform(color);
	return color;
}
vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) {
	vec4 color = texture2D(bitmap, coord);
	apply_flixel_transform(color);
	return color;
}

#define map(value, min1, max1, min2, max2) min2 + (value - min1) * (max2 - min2) / (max1 - min1)

vec2 getCamPos(vec2 pos) {
	vec4 size = _camSize / openfl_TextureSize.xyxy;
	return (pos - size.xy) / size.zw;
}
vec2 camToOg(vec2 pos) {
	vec4 size = _camSize / openfl_TextureSize.xyxy;
	return size.xy + pos * size.zw;
}
#define textureCam(bitmap, pos) flixel_texture2D(bitmap, camToOg(pos))")

	// There's no reason you need #pragma body in your shaders
	@:glFragmentBody("gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);")

	@:glFragmentSource("#define NO_GUARD_APPLY_FLIXEL_TRANSFORM
#pragma header
void main(void) {
	if (openfl_Alphav == 0.0) gl_FragColor = vec4(0.0);
	else {
		vec4 color = texture2D(bitmap, openfl_TextureCoordv);
		if (color.a != 0.0) apply_flixel_transform(color);
		gl_FragColor = color;
	}
}")
	public function new()
	{
		super();
	}

	public function setCamSize(x:Float, y:Float, width:Float, height:Float)
	{
		data._camSize.value = [x, y, width, height];
	}
}
