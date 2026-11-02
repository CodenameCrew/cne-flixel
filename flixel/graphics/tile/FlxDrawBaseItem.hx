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

	static var hasTransformValue:Array<Bool> = [true];

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

	var hasColorTransformValue:Array<Bool> = [false];
	var tempIndex:Int;
	var tempIndex2:Int;

	public function new() {
		colorMultipliers = alphas = [];
	}

	inline function baseReset() {
		nextTyped = null;
		next = null;

		hasColorTransformValue[0] = colored;

		alphas.resize(0);
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

	function addColorTransform(transform:ColorTransform, repeat:Int = 1) {
		if (transform == null) transform = colorIdentity;

		if (colored) {
			colorMultipliers.resize((tempIndex = colorMultipliers.length) + 4 * repeat);
			if (hasColorOffsets) {
				colorOffsets.resize((tempIndex2 = colorOffsets.length) + 4 * repeat);
				while (repeat-- > 0) {
					colorMultipliers[tempIndex++] = transform.redMultiplier;
					colorMultipliers[tempIndex++] = transform.greenMultiplier;
					colorMultipliers[tempIndex++] = transform.blueMultiplier;
					colorMultipliers[tempIndex++] = transform.alphaMultiplier;
					colorOffsets[tempIndex2++] = transform.redOffset;
					colorOffsets[tempIndex2++] = transform.greenOffset;
					colorOffsets[tempIndex2++] = transform.blueOffset;
					colorOffsets[tempIndex2++] = transform.alphaOffset;
				}
			}
			else {
				while (repeat-- > 0) {
					colorMultipliers[tempIndex++] = transform.redMultiplier;
					colorMultipliers[tempIndex++] = transform.greenMultiplier;
					colorMultipliers[tempIndex++] = transform.blueMultiplier;
					colorMultipliers[tempIndex++] = transform.alphaMultiplier;
				}
			}
		}
		else {
			alphas.resize((tempIndex = alphas.length) + repeat);
			if (hasColorOffsets) {
				colorOffsets.resize((tempIndex2 = colorOffsets.length) + 4 * repeat);
				while (repeat-- > 0) {
					alphas[tempIndex++] = transform.alphaMultiplier;
					colorOffsets[tempIndex2++] = transform.redOffset;
					colorOffsets[tempIndex2++] = transform.greenOffset;
					colorOffsets[tempIndex2++] = transform.blueOffset;
					colorOffsets[tempIndex2++] = transform.alphaOffset;
				}
			}
			else {
				while (repeat-- > 0) alphas[tempIndex++] = transform.alphaMultiplier;
			}
		}
	}

	function addColorTransforms(transforms:Array<ColorTransform>, n:Int) {
		var transform = colorIdentity;
		if (colored) {
			colorMultipliers.resize((tempIndex = colorMultipliers.length) + 4 * n);
			if (hasColorOffsets) {
				colorOffsets.resize((tempIndex2 = colorOffsets.length) + 4 * n);
				for (i in 0...n) {
					if (transforms != null) transform = transforms[i] ?? colorIdentity;
					colorMultipliers[tempIndex++] = transform.redMultiplier;
					colorMultipliers[tempIndex++] = transform.greenMultiplier;
					colorMultipliers[tempIndex++] = transform.blueMultiplier;
					colorMultipliers[tempIndex++] = transform.alphaMultiplier;
					colorOffsets[tempIndex2++] = transform.redOffset;
					colorOffsets[tempIndex2++] = transform.greenOffset;
					colorOffsets[tempIndex2++] = transform.blueOffset;
					colorOffsets[tempIndex2++] = transform.alphaOffset;
				}
			}
			else {
				for (i in 0...n) {
					if (transforms != null) transform = transforms[i] ?? colorIdentity;
					colorMultipliers[tempIndex++] = transform.redMultiplier;
					colorMultipliers[tempIndex++] = transform.greenMultiplier;
					colorMultipliers[tempIndex++] = transform.blueMultiplier;
					colorMultipliers[tempIndex++] = transform.alphaMultiplier;
				}
			}
		}
		else {
			alphas.resize((tempIndex = alphas.length) + transforms.length);
			if (hasColorOffsets) {
				colorOffsets.resize((tempIndex2 = colorOffsets.length) + 4 * transforms.length);
				for (i in 0...n) {
					if (transforms != null) transform = transforms[i] ?? colorIdentity;
					alphas[tempIndex++] = transform.alphaMultiplier;
					colorOffsets[tempIndex2++] = transform.redOffset;
					colorOffsets[tempIndex2++] = transform.greenOffset;
					colorOffsets[tempIndex2++] = transform.blueOffset;
					colorOffsets[tempIndex2++] = transform.alphaOffset;
				}
			}
			else {
				for (i in 0...n) {
					if (transforms != null) transform = transforms[i] ?? colorIdentity;
					alphas[tempIndex++] = transform.alphaMultiplier;
				}
			}
		}
	}

	function bindToShader(camera:FlxCamera, shader:FlxShader) {
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.wrap = wrapMode;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;

		shader.hasTransform.value = hasTransformValue;
		shader.hasColorTransform.value = hasColorTransformValue;

		shader.alpha.value = colored ? null : alphas;
		shader.colorMultiplier.value = colored ? colorMultipliers : null;
		shader.colorOffset.value = hasColorOffsets ? colorOffsets : null;

		camera.canvas.graphics.overrideBlendMode(blend);
		camera.canvas.graphics.overrideDepthTest(depthCompareMode != ALWAYS, depthCompareMode);
		camera.canvas.graphics.beginShaderFill(shader);
	}

	inline function setParameterValue(parameter:ShaderParameter<Bool>, value:Bool) {
		if (parameter.value == null) parameter.value = [value];
		else parameter.value[0] = value;
	}
}

enum FlxDrawItemType {
	TILES;
	TRIANGLES;
}