package flixel.graphics.tile;

import openfl.display.BlendMode;
import openfl.display.ShaderParameter;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DWrapMode;
import openfl.geom.ColorTransform;

import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import flixel.FlxCamera;

class FlxDrawBaseItem<T> {
	public static var colorIdentity:ColorTransform = new ColorTransform();
	public static var drawCalls:Int = 0;

	public var nextTyped:T;
	public var next:FlxDrawBaseItem<T>;
	public var type:FlxDrawItemType;

	public var numVertices(get, never):Int;
	public var numTriangles(get, never):Int;

	public var shader:Null<FlxShader>;
	public var graphics:FlxGraphic;
	public var antialiasing:Bool = false;
	public var colored:Bool = false;
	public var hasColorOffsets:Bool = false;
	public var blend:BlendMode = NORMAL;
	public var wrapMode:Context3DWrapMode = CLAMP;
	public var depthCompareMode:Context3DCompareMode = ALWAYS;

	// colorMultipliers is alphas, it's there to not confuse with variable naming
	// if colored, it'll use shader.colorMultiplier uniform, if not, shader.alpha uniform
	var alphas:Array<Float>;
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	public function new() {
		colorMultipliers = alphas = [];
	}

	inline function baseReset() {
		nextTyped = null;
		next = null;

		//alphas.resize(0);
		colorMultipliers.resize(0);
		if (colorOffsets != null) colorOffsets.resize(0);
		else if (hasColorOffsets) colorOffsets = [];
	}
	public function reset() baseReset();

	inline function baseDispose() {
		graphics = null;
		next = null;
		type = null;
		nextTyped = null;

		alphas = null;
		colorMultipliers = null;
		colorOffsets = null;
	}
	public function dispose() baseDispose();

	public function render(camera:FlxCamera) {}

	public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform) {}

	function get_numVertices():Int return 0;
	function get_numTriangles():Int return 0;

	inline function setParameterValue(parameter:ShaderParameter<Bool>, value:Bool) {
		if (parameter.value == null) parameter.value = [value];
		else parameter.value[0] = value;
	}

	inline function addColorTransform(transform:ColorTransform) {
		if (colored) {
			colorMultipliers.push(transform.redMultiplier);
			colorMultipliers.push(transform.greenMultiplier);
			colorMultipliers.push(transform.blueMultiplier);
			colorMultipliers.push(transform.alphaMultiplier);
		}
		else
			alphas.push(transform.alphaMultiplier);

		if (hasColorOffsets) {
			colorOffsets.push(transform.redOffset);
			colorOffsets.push(transform.greenOffset);
			colorOffsets.push(transform.blueOffset);
			colorOffsets.push(transform.alphaOffset);
		}
	}

	inline function bindToShader(camera:FlxCamera, shader:FlxShader) {
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.wrap = wrapMode;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;

		setParameterValue(shader.hasTransform, true);
		setParameterValue(shader.hasColorTransform, colored);

		@:privateAccess
		setParameterValue(shader.premultiplyAlpha, !graphics.bitmap.readable && graphics.bitmap.__texture != null && graphics.bitmap.__texture.__premultiplyAlpha);

		shader.alpha.value = colored ? null : alphas;
		shader.colorMultiplier.value = colored ? colorMultipliers : null;
		shader.colorOffset.value = hasColorOffsets ? colorOffsets : null;

		camera.canvas.graphics.overrideBlendMode(blend);
		camera.canvas.graphics.beginShaderFill(shader);
		camera.canvas.graphics.overrideDepthTest(depthCompareMode != ALWAYS, depthCompareMode);
	}
}

enum FlxDrawItemType {
	TILES;
	TRIANGLES;
}