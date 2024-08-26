package flixel;

import openfl.display.BitmapData;
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
	public function startQuadBatch(graphic:FlxGraphic, colored:Bool, hasColorOffsets:Bool = false, ?blend:BlendMode, smooth:Bool = false, ?shader:FlxShader)
	{
		#if FLX_RENDER_TRIANGLE
		return startTrianglesBatch(graphic, smooth, colored, blend);
		#else
		var itemToReturn = null;

		if (_currentDrawItem != null
			&& _currentDrawItem.type == FlxDrawItemType.TILES
			&& _headTiles.graphics == graphic
			&& _headTiles.colored == colored
			&& _headTiles.hasColorOffsets == hasColorOffsets
			&& _headTiles.blend == blend
			&& _headTiles.antialiasing == smooth
			&& _headTiles.shader == shader)
		{
			return _headTiles;
		}

		if (_storageTilesHead != null)
		{
			itemToReturn = _storageTilesHead;
			var newHead = _storageTilesHead.nextTyped;
			itemToReturn.reset();
			_storageTilesHead = newHead;
		}
		else
		{
			itemToReturn = new FlxDrawItem();
		}

		itemToReturn.graphics = graphic;
		itemToReturn.antialiasing = smooth;
		itemToReturn.colored = colored;
		itemToReturn.hasColorOffsets = hasColorOffsets;
		itemToReturn.blend = blend;
		itemToReturn.shader = shader;

		itemToReturn.nextTyped = _headTiles;
		_headTiles = itemToReturn;

		if (_headOfDrawStack == null)
		{
			_headOfDrawStack = itemToReturn;
		}

		if (_currentDrawItem != null)
		{
			_currentDrawItem.next = itemToReturn;
		}

		_currentDrawItem = itemToReturn;

		return itemToReturn;
		#end
	}

	@:noCompletion
	public function startTrianglesBatch(graphic:FlxGraphic, smoothing:Bool = false, isColored:Bool = false, ?blend:BlendMode, ?hasColorOffsets:Bool,
			?shader:FlxShader):FlxDrawTrianglesItem
	{
		if (_currentDrawItem != null
			&& _currentDrawItem.type == FlxDrawItemType.TRIANGLES
			&& _headTriangles.graphics == graphic
			&& _headTriangles.antialiasing == smoothing
			&& _headTriangles.colored == isColored #if !flash
			&& _headTriangles.hasColorOffsets == hasColorOffsets
			&& _headTriangles.shader == shader #end
		)
		{
			return _headTriangles;
		}

		return getNewDrawTrianglesItem(graphic, smoothing, isColored, blend, hasColorOffsets, shader);
	}

	@:noCompletion
	public function getNewDrawTrianglesItem(graphic:FlxGraphic, smoothing:Bool = false, isColored:Bool = false, ?blend:BlendMode, ?hasColorOffsets:Bool,
			?shader:FlxShader):FlxDrawTrianglesItem
	{
		var itemToReturn:FlxDrawTrianglesItem = null;

		if (_storageTrianglesHead != null)
		{
			itemToReturn = _storageTrianglesHead;
			var newHead:FlxDrawTrianglesItem = _storageTrianglesHead.nextTyped;
			itemToReturn.reset();
			_storageTrianglesHead = newHead;
		}
		else
		{
			itemToReturn = new FlxDrawTrianglesItem();
		}

		itemToReturn.graphics = graphic;
		itemToReturn.antialiasing = smoothing;
		itemToReturn.colored = isColored;
		#if !flash
		itemToReturn.hasColorOffsets = hasColorOffsets;
		itemToReturn.shader = shader;
		#end

		itemToReturn.nextTyped = _headTriangles;
		_headTriangles = itemToReturn;

		if (_headOfDrawStack == null)
		{
			_headOfDrawStack = itemToReturn;
		}

		if (_currentDrawItem != null)
		{
			_currentDrawItem.next = itemToReturn;
		}

		_currentDrawItem = itemToReturn;

		return itemToReturn;
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
			?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader):Void
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
			var drawItem:FlxDrawTrianglesItem = startTrianglesBatch(frame.parent, smoothing, isColored, blend);
			#else
			var drawItem = startQuadBatch(frame.parent, isColored, hasColorOffsets, blend, smoothing, shader);
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
