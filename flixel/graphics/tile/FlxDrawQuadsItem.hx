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

	public function new() {
		super();
		type = TILES;
	}

	override function reset() {
		baseReset();

		rects.length = 0;
		transforms.length = 0;
	}

	override function dispose() {
		baseDispose();

		rects = null;
		transforms = null;
	}

	override function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform) {
		rects.push(frame.frame.x); rects.push(frame.frame.y);
		rects.push(frame.frame.width); rects.push(frame.frame.height);

		transforms.push(matrix.a); transforms.push(matrix.b); transforms.push(matrix.c);
		transforms.push(matrix.d); transforms.push(matrix.tx); transforms.push(matrix.ty);

		transform ??= FlxDrawBaseItem.colorIdentity;
		var vertices = VERTICES_PER_QUAD;
		while (vertices-- > 0) {
			addColorTransform(transform);
		}
	}

	public function addColoredQuad(frame:FlxFrame, matrix:FlxMatrix, ?transforms:Array<ColorTransform>) {
		rects.push(frame.frame.x); rects.push(frame.frame.y);
		rects.push(frame.frame.width); rects.push(frame.frame.height);

		this.transforms.push(matrix.a); this.transforms.push(matrix.b); this.transforms.push(matrix.c);
		this.transforms.push(matrix.d); this.transforms.push(matrix.tx); this.transforms.push(matrix.ty);

		var i = 0, transformsLength = transforms?.length ?? 0;
		while (i < VERTICES_PER_QUAD) {
			addColorTransform(i < transformsLength ? transforms[i] : FlxDrawBaseItem.colorIdentity);
			i++;
		}
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