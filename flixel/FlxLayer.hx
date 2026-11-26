package flixel;

import openfl.display.BitmapData;
import openfl.display.TriangleCulling;
import openfl.display3D.Context3DWrapMode;
import openfl.display3D.Context3DCompareMode;
import openfl.geom.ColorTransform;
import flixel.graphics.FlxGraphic;
import flixel.graphics.FlxRenderTexture;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.graphics.tile.FlxDrawQuadsItem;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BlendMode;
import flixel.FlxCamera;

using flixel.util.FlxColorTransformUtil;

@:access(flixel.FlxCamera)
class FlxLayer extends FlxBasic
{
	/**
	 * Turn this off if you want a grouped layer rather than a textured one or just want the original behavior
	 */
	public var layerAsTexture:Bool = true;
	
	/**
	 * all of these only apply to textured layer
	 */
	public var alpha:Float = 1;
	
	public var colorTransform:ColorTransform;
	
	public var blend:BlendMode = NORMAL;
	
	public var antialiasing:Bool = false;
	
	public var shader:FlxShader;
	
	public var angle:Float = 0;
	
	public var originX:Float = 0;
	
	public var originY:Float = 0;
	
	/**
	 * One render target per camera (textured).
	 */
	var _targets:Map<FlxCamera, FlxLayerTarget> = [];
	
	/**
	 * for grouped layers
	 */
	var _groupedItems:Map<FlxCamera, FlxLayerDrawItem> = [];
	
	var _groupedCamera:FlxCamera;
	
	/**
	 * Currently used draw stack item (grouped)
	 */
	var _currentDrawItem:FlxDrawBaseItem<Dynamic>;

	/**
	 * Pointer to head of stack with draw items (grouped)
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
		for (target in _targets)
		{
			target.item.dispose();
			target.texture.destroy();
		}
		_targets = null;
		
		for (item in _groupedItems)
			item.dispose();
		_groupedItems = null;
		_groupedCamera = null;
		
		colorTransform = null;
		shader = null;

		super.destroy();
	}

	/**
	 * Gets or creates the render texture used for a camera Resizes it if the camera size changed.
	 */
	function getTarget(camera:FlxCamera):FlxLayerTarget
	{
		var target = _targets.get(camera);
		if (target == null)
		{
			target = new FlxLayerTarget(this, new FlxRenderTexture(camera.width, camera.height));
			_targets.set(camera, target);
		}
		else if (target.texture.width != camera.width || target.texture.height != camera.height)
		{
			target.texture.init(camera.width, camera.height);
			target.used = false;
		}
		return target;
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

		return getNewDrawTrianglesItem(graphic, smoothing, isColored, blend, hasColorOffsets, shader, wrapMode, depthCompareMode, culling);
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
		for (camera => target in _targets)
		{
			if (target.used || target.texture.width != camera.width || target.texture.height != camera.height)
			{
				target.texture.init(camera.width, camera.height);
				target.used = false;
			}
		}

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
		_groupedCamera = null;
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
			camera.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader, wrapMode, depthCompareMode);
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
		else if (layerAsTexture)
		{
			if (!camera.rotateSprite && camera.angle != 0)
			{
				matrix.translate(-camera.width / 2, -camera.height / 2);
				matrix.rotateWithTrig(camera._cosAngle, camera._sinAngle);
				matrix.translate(camera.width / 2, camera.height / 2);
			}
			
			var target = getTarget(camera);
			target.used = true;
			target.texture.camera.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader, wrapMode, depthCompareMode);
		}
		else
		{
			_groupedCamera = camera;

			// 1. Apply camera rotation (if any)
			if (!camera.rotateSprite && camera.angle != 0)
			{
				matrix.translate(-camera.width / 2, -camera.height / 2);
				matrix.rotateWithTrig(camera._cosAngle, camera._sinAngle);
				matrix.translate(camera.width / 2, camera.height / 2);
			}

			// 2. Apply layer rotation
			if (angle != 0)
			{
				var ox = originX != 0 ? originX : camera.width / 2;
				var oy = originY != 0 ? originY : camera.height / 2;
				var rad = angle * Math.PI / 180;
				matrix.translate(-ox, -oy);
				matrix.rotateWithTrig(Math.cos(rad), Math.sin(rad));
				matrix.translate(ox, oy);
			}
			
			// 3. Apply layer alpha and colorTransform
			var finalTransform = transform;
			if (alpha != 1 || (colorTransform != null && (colorTransform.hasRGBMultipliers() || colorTransform.hasRGBAOffsets())))
			{
				var rm = 1.0, gm = 1.0, bm = 1.0, am = alpha;
				var ro = 0.0, go = 0.0, bo = 0.0, ao = 0.0;
				
				if (transform != null)
				{
					rm = transform.redMultiplier;
					gm = transform.greenMultiplier;
					bm = transform.blueMultiplier;
					am *= transform.alphaMultiplier;
					ro = transform.redOffset;
					go = transform.greenOffset;
					bo = transform.blueOffset;
					ao = transform.alphaOffset;
				}
				
				if (colorTransform != null)
				{
					rm *= colorTransform.redMultiplier;
					gm *= colorTransform.greenMultiplier;
					bm *= colorTransform.blueMultiplier;
					am *= colorTransform.alphaMultiplier;
					ro += colorTransform.redOffset;
					go += colorTransform.greenOffset;
					bo += colorTransform.blueOffset;
					ao += colorTransform.alphaOffset;
				}
				
				finalTransform = new ColorTransform(rm, gm, bm, am, ro, go, bo, ao);
			}
			
			var isColored = (finalTransform != null && finalTransform.hasRGBMultipliers());
			var hasColorOffsets:Bool = (finalTransform != null && finalTransform.hasRGBAOffsets());
			
			// 4. Apply layer blend, shader, and antialiasing to the draw batch
			var finalBlend = blend != null ? blend : this.blend;
			var finalShader = shader != null ? shader : this.shader;
			var finalSmoothing = smoothing || this.antialiasing;

			#if FLX_RENDER_TRIANGLE
			var drawItem:FlxDrawTrianglesItem = startTrianglesBatch(frame.parent, finalSmoothing, isColored, finalBlend, hasColorOffsets, finalShader,
				wrapMode, depthCompareMode);
			#else
			var drawItem = startQuadBatch(frame.parent, isColored, hasColorOffsets, finalBlend, finalSmoothing, finalShader, wrapMode, depthCompareMode);
			#end
			drawItem.addQuad(frame, matrix, finalTransform);
		}
	}

	public function injectDrawCall(camera:FlxCamera, drawItem:FlxDrawBaseItem<Dynamic>):Void
	{
		drawItem.next = null;

		if (camera._headOfDrawStack == null)
		{
			camera._headOfDrawStack = drawItem;
		}
		else
		{
			camera._currentDrawItem.next = drawItem;
		}

		camera._currentDrawItem = drawItem;
	}

	public override function draw()
	{
		if (FlxG.renderBlit)
			return;
			
		if (layerAsTexture)
		{
			for (cam in cameras)
			{
				if (cam == null || !cam.exists || !cam.visible)
					continue;
					
				var target = getTarget(cam);
				injectDrawCall(cam, target.item);
			}
		}
		else
		{
			for (cam in cameras)
			{
				if (cam == null || !cam.exists || !cam.visible)
					continue;
					
				var item = _groupedItems.get(cam);
				if (item == null)
				{
					item = new FlxLayerDrawItem(this, null);
					_groupedItems.set(cam, item);
				}
				injectDrawCall(cam, item);
			}
		}
	}
	
	@:noCompletion
	public function renderGrouped(cam:FlxCamera):Void
	{
		if (cam != _groupedCamera)
			return;
			
		var item:FlxDrawBaseItem<Dynamic> = _headOfDrawStack;
		while (item != null)
		{
			item.render(cam);
			item = item.next;
		}
	}
	
	@:noCompletion
	public function renderTarget(cam:FlxCamera, target:FlxLayerTarget):Void
	{
		if (!target.used)
			return;
			
		var texture = target.texture;
		texture.antialiasing = antialiasing;
		texture.render();
		
		var transform:Null<ColorTransform> = null;
		if (alpha != 1 || (colorTransform != null && (colorTransform.hasRGBMultipliers() || colorTransform.hasRGBAOffsets())))
		{
			transform = target.transform;
			if (colorTransform != null)
			{
				transform.redMultiplier = colorTransform.redMultiplier;
				transform.greenMultiplier = colorTransform.greenMultiplier;
				transform.blueMultiplier = colorTransform.blueMultiplier;
				transform.alphaMultiplier = colorTransform.alphaMultiplier;
				transform.redOffset = colorTransform.redOffset;
				transform.greenOffset = colorTransform.greenOffset;
				transform.blueOffset = colorTransform.blueOffset;
				transform.alphaOffset = colorTransform.alphaOffset;
			}
			else
			{
				transform.redMultiplier = transform.greenMultiplier = transform.blueMultiplier = transform.alphaMultiplier = 1;
				transform.redOffset = transform.greenOffset = transform.blueOffset = transform.alphaOffset = 0;
			}
			transform.alphaMultiplier *= alpha;
		}
		
		var quad = target.quad;
		quad.graphics = texture.graphic;
		quad.antialiasing = antialiasing;
		quad.colored = transform != null && transform.hasRGBMultipliers();
		quad.hasColorOffsets = transform != null && transform.hasRGBAOffsets();
		quad.blend = blend;
		quad.shader = shader;
		quad.reset();
		
		target.matrix.identity();
		
		if (angle != 0)
		{
			var ox = originX != 0 ? originX : texture.width / 2;
			var oy = originY != 0 ? originY : texture.height / 2;
			var rad = angle * Math.PI / 180;
			target.matrix.translate(-ox, -oy);
			target.matrix.rotateWithTrig(Math.cos(rad), Math.sin(rad));
			target.matrix.translate(ox, oy);
		}
		
		quad.addQuad(texture.graphic.imageFrame.frame, target.matrix, transform);
		quad.render(cam);
	}
}

private class FlxLayerDrawItem extends FlxDrawBaseItem<FlxLayerDrawItem>
{
	var layer:FlxLayer;
	var target:FlxLayerTarget;
	
	public function new(layer:FlxLayer, target:FlxLayerTarget)
	{
		super();
		this.layer = layer;
		this.target = target;
		type = null;
	}
	
	override function render(camera:FlxCamera):Void
	{
		if (target != null)
			layer.renderTarget(camera, target);
		else
			layer.renderGrouped(camera);
	}
	override function dispose():Void
	{
		layer = null;
		target = null;
		baseDispose();
	}
}

/**
 * Per-camera render target of a `FlxLayer`.
 */
@:allow(flixel.FlxLayer)
private class FlxLayerTarget
{
	public var texture:FlxRenderTexture;
	public var item:FlxLayerDrawItem;
	public var quad:#if FLX_RENDER_TRIANGLE FlxDrawTrianglesItem #else FlxDrawQuadsItem #end;
	public var matrix:FlxMatrix = new FlxMatrix();
	public var transform:ColorTransform = new ColorTransform();
	
	public var used:Bool = false;
	
	public function new(layer:FlxLayer, texture:FlxRenderTexture)
	{
		this.texture = texture;
		this.item = new FlxLayerDrawItem(layer, this);
		this.quad = #if FLX_RENDER_TRIANGLE new FlxDrawTrianglesItem() #else new FlxDrawQuadsItem() #end;
	}
}