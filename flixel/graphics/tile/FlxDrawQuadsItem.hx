package flixel.graphics.tile;

import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.system.FlxAssets.FlxShader;
import flixel.math.FlxMatrix;
import openfl.geom.ColorTransform;
import openfl.display.ShaderParameter;
import openfl.Vector;

class FlxDrawQuadsItem extends FlxDrawBaseItem<FlxDrawQuadsItem>
{
	static inline var VERTICES_PER_QUAD = #if (openfl >= "8.5.0") 4 #else 6 #end;

	public var shader:FlxShader;

	var rects:Vector<Float>;
	var transforms:Vector<Float>;
	var alphas:Array<Float>;
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	public function new()
	{
		super();
		type = FlxDrawItemType.TILES;
		rects = new Vector<Float>();
		transforms = new Vector<Float>();
		alphas = [];
	}

	override public function reset():Void
	{
		super.reset();
		rects.length = 0;
		transforms.length = 0;
		alphas.splice(0, alphas.length);
		if (colorMultipliers != null)
			colorMultipliers.splice(0, colorMultipliers.length);
		if (colorOffsets != null)
			colorOffsets.splice(0, colorOffsets.length);
	}

	override public function dispose():Void
	{
		super.dispose();
		rects = null;
		transforms = null;
		alphas = null;
		colorMultipliers = null;
		colorOffsets = null;
	}

	override public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void
	{
		var rect = frame.frame;

		/*var len = rects.length;
			rects.length += 4;
			rects[len++] = rect.x;
			rects[len++] = rect.y;
			rects[len++] = rect.width;
			rects[len++] = rect.height;

			len = transforms.length;
			transforms.length += 6;
			transforms[len++] = matrix.a;
			transforms[len++] = matrix.b;
			transforms[len++] = matrix.c;
			transforms[len++] = matrix.d;
			transforms[len++] = matrix.tx;
			transforms[len++] = matrix.ty; */

		rects.push(rect.x);
		rects.push(rect.y);
		rects.push(rect.width);
		rects.push(rect.height);

		transforms.push(matrix.a);
		transforms.push(matrix.b);
		transforms.push(matrix.c);
		transforms.push(matrix.d);
		transforms.push(matrix.tx);
		transforms.push(matrix.ty);

		var alphaMultiplier = transform != null ? transform.alphaMultiplier : 1.0;
		var len = alphas.length;
		alphas.resize(len + VERTICES_PER_QUAD);
		for (i in 0...VERTICES_PER_QUAD)
			alphas[len++] = alphaMultiplier;

		if (colored || hasColorOffsets)
		{
			if (colorMultipliers == null)
				colorMultipliers = [];

			if (colorOffsets == null)
				colorOffsets = [];

			var lenm = colorMultipliers.length;
			colorMultipliers.resize(lenm + 4 * VERTICES_PER_QUAD);
			var leno = colorOffsets.length;
			colorOffsets.resize(leno + 4 * VERTICES_PER_QUAD);

			for (i in 0...VERTICES_PER_QUAD)
			{
				if (transform != null)
				{
					colorMultipliers[lenm++] = transform.redMultiplier;
					colorMultipliers[lenm++] = transform.greenMultiplier;
					colorMultipliers[lenm++] = transform.blueMultiplier;
					colorMultipliers[lenm++] = 1;

					colorOffsets[leno++] = transform.redOffset;
					colorOffsets[leno++] = transform.greenOffset;
					colorOffsets[leno++] = transform.blueOffset;
					colorOffsets[leno++] = transform.alphaOffset;
				}
				else
				{
					colorMultipliers[lenm++] = 1;
					colorMultipliers[lenm++] = 1;
					colorMultipliers[lenm++] = 1;
					colorMultipliers[lenm++] = 1;

					colorOffsets[leno++] = 0;
					colorOffsets[leno++] = 0;
					colorOffsets[leno++] = 0;
					colorOffsets[leno++] = 0;
				}
			}
		}
	}

	#if debug
	private static var ERROR_BITMAP = new openfl.display.BitmapData(1, 1, true, 0xFFff0000);
	#end
	#if ANTIALIASING_DEBUG
	private static var ALPHA_ERROR_BITMAP = new openfl.display.BitmapData(1, 1, true, 0x40ff0000);
	#end
	#if DRAW_CALLS_DEBUG
	private static var randColors:Array<openfl.display.BitmapData> = [];
	#end

	#if !flash
	override public function render(camera:FlxCamera):Void
	{
		if (rects.length == 0)
			return;

		var shader = shader != null ? shader : graphics.shader;

		if (shader == null || graphics == null || shader.bitmap == null || graphics.bitmap == null)
			return;
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.filter = (FlxG.enableAntialiasing && (camera.antialiasing || antialiasing)) ? LINEAR : NEAREST;
		shader.alpha.value = alphas;

		if (colored || hasColorOffsets)
		{
			shader.colorMultiplier.value = colorMultipliers;
			shader.colorOffset.value = colorOffsets;
		}

		setParameterValue(shader.hasTransform, true);
		setParameterValue(shader.hasColorTransform, colored || hasColorOffsets);

		#if (openfl > "8.7.0")
		camera.canvas.graphics.overrideBlendMode(blend);
		#end
		camera.canvas.graphics.beginShaderFill(shader);
		camera.canvas.graphics.drawQuads(rects, null, transforms);

		#if ANTIALIASING_DEBUG
		if (!antialiasing)
		{
			#if debug
			#if (openfl > "8.7.0")
			camera.canvas.graphics.overrideBlendMode(blend);
			#end
			camera.canvas.graphics.beginBitmapFill(ALPHA_ERROR_BITMAP);
			camera.canvas.graphics.drawQuads(rects, null, transforms);
			camera.canvas.graphics.endFill();
			#end
		}
		#end

		#if DRAW_CALLS_DEBUG
		var drawCalls = FlxDrawBaseItem.drawCalls;

		while (randColors[drawCalls] == null)
		{
			var color = FlxColor.fromRGB(Std.int(Math.random() * 255), Std.int(Math.random() * 255), Std.int(Math.random() * 255), 0x40);
			randColors.push(new openfl.display.BitmapData(1, 1, true, color));
		}

		#if (openfl > "8.7.0")
		camera.canvas.graphics.overrideBlendMode(blend);
		#end
		camera.canvas.graphics.beginBitmapFill(randColors[drawCalls]);
		camera.canvas.graphics.drawQuads(rects, null, transforms);
		camera.canvas.graphics.endFill();
		#end
		super.render(camera);
	}

	inline function setParameterValue(parameter:ShaderParameter<Bool>, value:Bool):Void
	{
		if (parameter.value == null)
			parameter.value = [];
		parameter.value[0] = value;
	}
	#end
}
