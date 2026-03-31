package flixel;

import openfl.display.BitmapData;
import openfl.display.TriangleCulling;
import openfl.display3D.Context3DWrapMode;
import openfl.display3D.Context3DCompareMode;
import openfl.geom.ColorTransform;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BlendMode;
import flixel.FlxCamera;

using flixel.util.FlxColorTransformUtil;

@:access(flixel.FlxCamera)
class FlxLayer extends FlxBasic
{
	/**
	 * Currently used draw stack item
	 */
	var _currentDrawItem:FlxDrawBaseItem<Dynamic>;

	/**
	 * Pointer to head of stack with draw items
	 */
	var _headOfDrawStack:FlxDrawBaseItem<Dynamic>;

	/**
	 * Last draw tiles item
	 */
	var _headTiles:FlxDrawItem;

	/**
	 * Last draw triangles item
	 */
	var _headTriangles:FlxDrawTrianglesItem;

	/**
	 * Draw tiles stack items that can be reused
	 */
	static var _storageTilesHead:FlxDrawItem;

	/**
	 * Draw triangles stack items that can be reused
	 */
	static var _storageTrianglesHead:FlxDrawTrianglesItem;

	public function new()
	{
		super();
		FlxG.signals.preDraw.add(clearDrawStack);
	}

	override function destroy():Void
	{
		FlxG.signals.preDraw.remove(clearDrawStack);
		super.destroy();
	}

	@:noCompletion
	public function startQuadBatch(graphic:FlxGraphic, colored:Bool, hasColorOffsets:Bool = false, ?blend:BlendMode, smooth:Bool = false, ?shader:FlxShader,
		?wrapMode:Context3DWrapMode, ?depthCompareMode:Context3DCompareMode)
	{
		if (blend == null) blend = NORMAL;
		if (wrapMode == null) wrapMode = CLAMP;
		if (depthCompareMode == null) depthCompareMode = ALWAYS;

		if (_currentDrawItem != null
			&& _currentDrawItem.type == flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType.TILES
			&& _headTiles.graphics == graphic
			&& _headTiles.colored == colored
			&& _headTiles.hasColorOffsets == hasColorOffsets
			&& _headTiles.blend == blend
			&& _headTiles.antialiasing == smooth
			&& _headTiles.shader == shader
			&& _headTiles.wrapMode == wrapMode
			&& _headTiles.depthCompareMode == depthCompareMode
		)
			return _headTiles;

		var item = _storageTilesHead;
		if (item != null) _storageTilesHead = _storageTilesHead.nextTyped;
		else item = new flixel.graphics.tile.FlxDrawQuadsItem();

		item.graphics = graphic;
		item.antialiasing = smooth;
		item.colored = colored;
		item.hasColorOffsets = hasColorOffsets;
		item.blend = blend;
		item.shader = shader;
		item.wrapMode = wrapMode;
		item.depthCompareMode = depthCompareMode;
		item.reset();

		item.nextTyped = _headTiles;
		_headTiles = item;

		if (_headOfDrawStack == null) _headOfDrawStack = item;
		if (_currentDrawItem != null) _currentDrawItem.next = item;
		_currentDrawItem = item;

		return item;
	}

	@:noCompletion
	public function startTrianglesBatch(graphic:FlxGraphic, smoothing:Bool = false, isColored:Bool = false, ?blend:BlendMode, ?hasColorOffsets:Bool,
			?shader:FlxShader, ?wrapMode:Context3DWrapMode, ?depthCompareMode:Context3DCompareMode, ?culling:TriangleCulling):FlxDrawTrianglesItem
	{
		if (blend == null) blend = NORMAL;
		if (wrapMode == null) wrapMode = CLAMP;
		if (depthCompareMode == null) depthCompareMode = ALWAYS;

		if (_currentDrawItem != null
			&& _currentDrawItem.type == flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType.TRIANGLES
			&& _headTriangles.graphics == graphic
			&& _headTriangles.antialiasing == smoothing
			&& _headTriangles.colored == isColored
			&& _headTriangles.blend == blend
			&& _headTriangles.hasColorOffsets == hasColorOffsets
			&& _headTriangles.shader == shader
			&& _headTriangles.culling == culling
			&& _headTriangles.wrapMode == wrapMode
			&& _headTriangles.depthCompareMode == depthCompareMode
		)
			return _headTriangles;

		return getNewDrawTrianglesItem(graphic, smoothing, isColored, blend, hasColorOffsets, shader, depthCompareMode, culling);
	}

	@:noCompletion
	public function getNewDrawTrianglesItem(graphic:FlxGraphic, smoothing:Bool = false, isColored:Bool = false, ?blend:BlendMode, ?hasColorOffsets:Bool,
			?shader:FlxShader, ?wrapMode:Context3DWrapMode, ?depthCompareMode:Context3DCompareMode, ?culling:TriangleCulling):FlxDrawTrianglesItem
	{
		if (blend == null) blend = openfl.display.BlendMode.NORMAL;
		if (wrapMode == null) wrapMode = openfl.display3D.Context3DWrapMode.CLAMP;
		if (depthCompareMode == null) depthCompareMode = openfl.display3D.Context3DCompareMode.ALWAYS;

		var item = _storageTrianglesHead;
		if (item != null) _storageTrianglesHead = _storageTrianglesHead.nextTyped;
		else item = new flixel.graphics.tile.FlxDrawTrianglesItem();

		item.graphics = graphic;
		item.antialiasing = smoothing;
		item.colored = isColored;
		item.blend = blend;
		item.hasColorOffsets = hasColorOffsets;
		item.shader = shader;
		item.culling = culling;
		item.wrapMode = wrapMode;
		item.depthCompareMode = depthCompareMode;
		item.reset();

		item.nextTyped = _headTriangles;
		_headTriangles = item;

		if (_headOfDrawStack == null) _headOfDrawStack = item;
		if (_currentDrawItem != null) _currentDrawItem.next = item;
		_currentDrawItem = item;

		return item;
	}

	@:allow(flixel.system.frontEnds.CameraFrontEnd)
	function clearDrawStack():Void
	{
		var currTiles = _headTiles;
		var newTilesHead;

		while (currTiles != null)
		{
			newTilesHead = currTiles.nextTyped;
			currTiles.reset();
			currTiles.nextTyped = _storageTilesHead;
			_storageTilesHead = currTiles;
			currTiles = newTilesHead;
		}

		var currTriangles:FlxDrawTrianglesItem = _headTriangles;
		var newTrianglesHead:FlxDrawTrianglesItem;

		while (currTriangles != null)
		{
			newTrianglesHead = currTriangles.nextTyped;
			currTriangles.reset();
			currTriangles.nextTyped = _storageTrianglesHead;
			_storageTrianglesHead = currTriangles;
			currTriangles = newTrianglesHead;
		}

		_currentDrawItem = null;
		_headOfDrawStack = null;
		_headTiles = null;
		_headTriangles = null;
	}

	public function drawPixels(sprite:FlxSprite, camera:FlxCamera, ?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform,
			?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader, ?wrapMode:Context3DWrapMode, ?depthCompareMode:Context3DCompareMode):Void
	{
		var cameraExists = false;
		for (cam in cameras)
		{
			if (cam == camera)
			{
				cameraExists = true;
				break;
			}
		}

		if (!cameraExists)
		{
			FlxG.log.warn('Camera ${camera} is not added to the layer, drawing normally');
			camera.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
			return;
		}

		if (FlxG.renderBlit)
		{
			camera._helperMatrix.copyFrom(matrix);

			if (camera._useBlitMatrix)
			{
				camera._helperMatrix.concat(camera._blitMatrix);
				camera.buffer.draw(pixels, camera._helperMatrix, null, null, null, (smoothing || camera.antialiasing));
			}
			else
			{
				camera._helperMatrix.translate(-camera.viewMarginLeft, -camera.viewMarginTop);
				camera.buffer.draw(pixels, camera._helperMatrix, null, blend, null, (smoothing || camera.antialiasing));
			}
		}
		else
		{
			var isColored = (transform != null && transform.hasRGBMultipliers());
			var hasColorOffsets:Bool = (transform != null && transform.hasRGBAOffsets());

			if (!camera.rotateSprite && camera.angle != 0)
			{
				matrix.translate(-camera.width / 2, -camera.height / 2);
				matrix.rotateWithTrig(camera._cosAngle, camera._sinAngle);
				matrix.translate(camera.width / 2, camera.height / 2);
			}

			#if FLX_RENDER_TRIANGLE
			var drawItem:FlxDrawTrianglesItem = startTrianglesBatch(frame.parent, smoothing, isColored, blend, hasColorOffsets, shader,
				wrapMode, depthCompareMode);
			#else
			var drawItem = startQuadBatch(frame.parent, isColored, hasColorOffsets, blend, smoothing, shader, wrapMode, depthCompareMode);
			#end
			drawItem.addQuad(frame, matrix, transform);
		}
	}

	public function injectDrawCall(camera:FlxCamera, drawItem:FlxDrawItem):Void
	{
		drawItem.next = null;

		if (camera._headOfDrawStack == null)
		{
			camera._headOfDrawStack = drawItem;
		}
		else
		{
			// var current:FlxDrawBaseItem<Dynamic> = camera._headOfDrawStack;
			// while (current.next != null)
			// {
			//	current = current.next;
			// }
			// current.next = drawItem;
			camera._currentDrawItem.next = drawItem;
		}

		camera._currentDrawItem = drawItem;
	}

	public override function draw()
	{
		// TODO: support multiple cameras
		if (_headTiles != null)
		{
			injectDrawCall(camera, _headTiles);
		}
	}
}
