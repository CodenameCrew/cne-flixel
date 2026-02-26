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

uniform bool hasColorTransform;")

	@:glVertexBody("openfl_TextureCoordv = openfl_TextureCoord;

if (hasColorTransform) {
	openfl_Alphav = openfl_Alpha * colorMultiplier.a;
	if (openfl_HasColorTransform) {
		openfl_ColorOffsetv = (openfl_ColorOffset / 255.0 * colorMultiplier) + (colorOffset / 255.0);
		openfl_ColorMultiplierv = openfl_ColorMultiplier * vec4(colorMultiplier.rgb, 1.0);
	}
	else {
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = vec4(colorMultiplier.rgb, 1.0);
	}
}
else {
	openfl_Alphav = openfl_Alpha * alpha;
	if (openfl_HasColorTransform) {
		openfl_ColorOffsetv = (openfl_ColorOffset + colorOffset) / 255.0;
		openfl_ColorMultiplierv = openfl_ColorMultiplier;
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

vec4 apply_flixel_transform(vec4 color) {
	if (color.a <= 0.0 || openfl_Alphav == 0.0) return vec4(0.0);

	color.rgb /= color.a;
	color = clamp(openfl_ColorOffsetv + (color * openfl_ColorMultiplierv), 0.0, 1.0);
	return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
}

#define applyFlixelEffects(color) apply_flixel_transform(color)

vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) {
	vec4 color = texture2D(bitmap, coord);
	if (hasTransform) return apply_flixel_transform(color);
	else return color;
}

uniform vec4 _camSize;

float map(float value, float min1, float max1, float min2, float max2) {
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

vec2 getCamPos(vec2 pos) {
	vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
	return vec2(map(pos.x, size.x, size.x + size.z, 0.0, 1.0), map(pos.y, size.y, size.y + size.w, 0.0, 1.0));
}
vec2 camToOg(vec2 pos) {
	vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
	return vec2(map(pos.x, 0.0, 1.0, size.x, size.x + size.z), map(pos.y, 0.0, 1.0, size.y, size.y + size.w));
}
vec4 textureCam(sampler2D bitmap, vec2 pos) {
	return flixel_texture2D(bitmap, camToOg(pos));
}")

	@:glFragmentBody("gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
if (gl_FragColor.a == 0.0) discard;")

	@:glFragmentSource("#pragma header
void main(void) {
	#pragma body
}")
	public function new() {
		super();
	}
}
