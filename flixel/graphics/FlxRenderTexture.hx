package flixel.graphics;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMatrix;
import flixel.util.FlxDestroyUtil;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.OpenGLRenderer;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;

/**
 * Ported from flixel-animate's `RenderTexture`.
 */
@:access(flixel.FlxCamera)
@:access(flixel.graphics.FlxGraphic)
@:access(openfl.display.BitmapData)
@:access(openfl.display.DisplayObjectContainer)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.geom.ColorTransform)
class FlxRenderTexture implements IFlxDestroyable
{
	public var antialiasing:Bool = false;
	public var graphic(default, null):FlxGraphic;


	public var camera(get, never):FlxCamera;

	public var width(default, null):Int;
	public var height(default, null):Int;

	var _renderer:OpenGLRenderer;
	var _bitmaps:Map<String, BitmapData>;
	var _currentBitmap:BitmapData;
	var _camera:FlxCamera;
	var _matrix:FlxMatrix;

	public function new(width:Int, height:Int):Void
	{
		_renderer = new OpenGLRenderer(FlxG.stage.context3D);
		_renderer.__worldTransform = new Matrix();
		_renderer.__worldColorTransform = new ColorTransform();

		_bitmaps = [];
		_camera = new FlxCamera();
		_matrix = new FlxMatrix();

		init(width, height);
	}

	public function destroy():Void
	{
		_renderer.__cleanup();
		_renderer = null;

		for (bitmap in _bitmaps)
		{
			if (bitmap.__texture != null)
				bitmap.__texture.dispose();
			bitmap.dispose();
		}

		_bitmaps = null;
		_currentBitmap = null;

		_camera = FlxDestroyUtil.destroy(_camera);
		_matrix = null;

		graphic = FlxDestroyUtil.destroy(graphic);
	}

	public function init(width:Int, height:Int):Void
	{
		this.width = width;
		this.height = height;

		_camera.clearDrawStack();
		_camera.canvas.graphics.clear();
		#if FLX_DEBUG
		_camera.debugLayer.graphics.clear();
		#end
		_camera.width = width;
		_camera.height = height;

		_prepareTexture(width, height);
		graphic.bitmap = _currentBitmap;
		graphic.imageFrame.frame.frame.set(0, 0, width, height);

		_currentBitmap.__fillRect(_currentBitmap.rect, 0, true);
	}

	public function drawToCamera(drawCallback:FlxCamera->FlxMatrix->Void):Void
	{
		_matrix.identity();
		drawCallback(_camera, _matrix);
	}

	public function render():Void
	{
		_camera.render();
		_camera.canvas.__update(false, true);

		_renderer.__cleanup();

		_renderer.setShader(_renderer.__defaultShader);
		_renderer.__allowSmoothing = antialiasing;
		_renderer.__pixelRatio = #if openfl_disable_hdpi 1 #else Lib.current.stage.window.scale #end;
		_renderer.__worldAlpha = 1 / _camera.canvas.__worldAlpha;
		_renderer.__worldTransform.copyFrom(_camera.canvas.__renderTransform);
		_renderer.__worldTransform.invert();
		_renderer.__worldColorTransform.__copyFrom(_camera.canvas.__worldColorTransform);
		_renderer.__worldColorTransform.__invert();
		_renderer.__setRenderTarget(_currentBitmap);

		_currentBitmap.__drawGL(_camera.canvas, _renderer);
	}

	function _prepareTexture(width:Int, height:Int):Void
	{
		var requireTexture = _currentBitmap == null || (_currentBitmap.width != width || _currentBitmap.height != height);
		if (!requireTexture)
			return;

		final id:String = Std.string(width) + 'x' + Std.string(height);

		if (!_bitmaps.exists(id))
			_bitmaps.set(id, BitmapData.fromTexture(FlxG.stage.context3D.createRectangleTexture(width, height, BGRA, true)));

		_currentBitmap = _bitmaps.get(id);

		if (graphic == null)
			graphic = FlxGraphic.fromBitmapData(_currentBitmap, false, null, false);
	}

	inline function get_camera():FlxCamera
		return _camera;
}
