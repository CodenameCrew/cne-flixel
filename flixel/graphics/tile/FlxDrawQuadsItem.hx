package flixel.graphics.tile;

import openfl.geom.ColorTransform;
import openfl.Vector;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.math.FlxMatrix;
import flixel.FlxCamera;

class FlxDrawQuadsItem extends FlxDrawBaseItem<FlxDrawQuadsItem> {
	public static inline final VERTICES_PER_QUAD = 4;

	public var rects:Vector<Float> = new Vector<Float>();
	public var transforms:Vector<Float> = new Vector<Float>();

	#if !js
	var rectsArray:Array<Float>;
	var transformsArray:Array<Float>;
	#end

	public function new() {
		super();
		type = TILES;

		#if !js
		@:privateAccess rectsArray = untyped (rects).__array;
		@:privateAccess transformsArray = untyped (transforms).__array;
		#end
	}

	override function reset() {
		baseReset();

		#if js
		rects.length = 0;
		transforms.length = 0;
		#else
		rectsArray.resize(0);
		transformsArray.resize(0);
		#end
	}

	override function dispose() {
		baseDispose();

		rects.length = 0;
		transforms.length = 0;

		rects = null;
		transforms = null;
	}

	override function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform) {
		#if js
		rects.push(frame.frame.x); rects.push(frame.frame.y);
		rects.push(frame.frame.width); rects.push(frame.frame.height);

		transforms.push(matrix.a); transforms.push(matrix.b); transforms.push(matrix.c);
		transforms.push(matrix.d); transforms.push(matrix.tx); transforms.push(matrix.ty);
		#else
		rectsArray.resize((tempIndex = rectsArray.length) + 4);
		rectsArray[tempIndex++] = frame.frame.x; rectsArray[tempIndex++] = frame.frame.y;
		rectsArray[tempIndex++] = frame.frame.width; rectsArray[tempIndex++] = frame.frame.height;

		transformsArray.resize((tempIndex = transformsArray.length) + 6);
		transformsArray[tempIndex++] = matrix.a; transformsArray[tempIndex++] = matrix.b; transformsArray[tempIndex++] = matrix.c;
		transformsArray[tempIndex++] = matrix.d; transformsArray[tempIndex++] = matrix.tx; transformsArray[tempIndex++] = matrix.ty;
		#end

		addColorTransform(transform, VERTICES_PER_QUAD);
	}

	public function addColoredQuad(frame:FlxFrame, matrix:FlxMatrix, ?transforms:Array<ColorTransform>) {
		#if js
		rects.push(frame.frame.x); rects.push(frame.frame.y);
		rects.push(frame.frame.width); rects.push(frame.frame.height);

		this.transforms.push(matrix.a); this.transforms.push(matrix.b); this.transforms.push(matrix.c);
		this.transforms.push(matrix.d); this.transforms.push(matrix.tx); this.transforms.push(matrix.ty);
		#else
		rectsArray.resize((tempIndex = rectsArray.length) + 4);
		rectsArray[tempIndex++] = frame.frame.x; rectsArray[tempIndex++] = frame.frame.y;
		rectsArray[tempIndex++] = frame.frame.width; rectsArray[tempIndex++] = frame.frame.height;

		transformsArray.resize((tempIndex = transformsArray.length) + 6);
		transformsArray[tempIndex++] = matrix.a; transformsArray[tempIndex++] = matrix.b; transformsArray[tempIndex++] = matrix.c;
		transformsArray[tempIndex++] = matrix.d; transformsArray[tempIndex++] = matrix.tx; transformsArray[tempIndex++] = matrix.ty;
		#end

		addColorTransforms(transforms, VERTICES_PER_QUAD);
	}

	override function render(camera:FlxCamera):Void {
		//if (graphics.isDestroyed) throw 'Attempted to render an invalid FlxDrawQaudsItem, did you destroy a cached sprite?';
		if (rects.length == 0) return;

		final shader = shader ?? graphics.shader;
		bindToShader(camera, shader);

		camera.canvas.graphics.drawQuads(rects, null, transforms);
		camera.canvas.graphics.endFill();

		FlxDrawBaseItem.drawCalls++;
	}

	override function get_numVertices():Int return rects.length;
	override function get_numTriangles():Int return rects.length >> 1;
}