package flixel.graphics.tile;

import openfl.display.TriangleCulling;
import openfl.geom.ColorTransform;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.FlxCamera;

typedef DrawData<T> = openfl.Vector<T>;

class FlxDrawTrianglesItem extends FlxDrawBaseItem<FlxDrawTrianglesItem> {
	public static inline final INDICES_PER_QUAD = 6;

	static final point:FlxPoint = FlxPoint.get();
	static final rect:FlxRect = FlxRect.get();
	static final bounds = FlxRect.get();

	public static inline function inflateBounds(bounds:FlxRect, x:Float, y:Float):FlxRect {
		if (x < bounds.x) {
			bounds.width += bounds.x - x;
			bounds.x = x;
		}

		if (y < bounds.y) {
			bounds.height += bounds.y - y;
			bounds.y = y;
		}

		if (x > bounds.x + bounds.width) bounds.width = x - bounds.x;
		if (y > bounds.y + bounds.height) bounds.height = y - bounds.y;

		return bounds;
	}

	// unused in this fork
	public var verticesPosition:Int = 0;
	public var indicesPosition:Int = 0;
	public var colorsPosition:Int = 0;

	public var culling:TriangleCulling = NONE;
	public var vertices:DrawData<Float> = new DrawData<Float>();
	public var indices:DrawData<Int> = new DrawData<Int>();
	public var uvtData:DrawData<Float> = new DrawData<Float>();
	public var colors:DrawData<Int> = new DrawData<Int>();

	public function new() {
		super();
		type = TRIANGLES;
	}

	override function reset() {
		baseReset();

		//verticesPosition = 0;
		//indicesPosition = 0;
		//colorsPosition = 0;

		vertices.length = 0;
		indices.length = 0;
		uvtData.length = 0;
		colors.length = 0;
	}

	override function dispose() {
		baseDispose();

		vertices = null;
		indices = null;
		uvtData = null;
		colors = null;
	}

	public function addTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint,
		?cameraBounds:FlxRect, ?transform:ColorTransform)
	{
		if (position == null) position = point.set();
		cameraBounds?.putWeak(); // unused

		final prevNumberOfVertices = this.numVertices,
			verticesLength = (vertices.length >> 1) << 1,
			indicesLength = Math.floor(indices.length / 3) * 3;

		var i = 0;
		while (i < verticesLength) {
			this.uvtData.push(uvtData[i]);
			this.vertices.push(position.x + vertices[i]);
			this.uvtData.push(uvtData[++i]);
			this.vertices.push(position.y + vertices[i]);
			i++;
		}
		position.putWeak();

		final colorsLength = colors?.length ?? 0;
		var index = 0, color:FlxColor;
		transform ??= FlxDrawBaseItem.colorIdentity;

		i = 0;
		while (i < indicesLength) {
			if ((index = indices[i]) < colorsLength) {
				color = colors[index];
				if (colored) {
					colorMultipliers.push(transform.redMultiplier * color.redFloat);
					colorMultipliers.push(transform.greenMultiplier * color.greenFloat);
					colorMultipliers.push(transform.blueMultiplier * color.blueFloat);
					colorMultipliers.push(transform.alphaMultiplier * color.alphaFloat);
				}
				else
					alphas.push(transform.alphaMultiplier * color.alphaFloat);

				if (hasColorOffsets) {
					colorOffsets.push(transform.redOffset);
					colorOffsets.push(transform.greenOffset);
					colorOffsets.push(transform.blueOffset);
					colorOffsets.push(transform.alphaOffset);
				}
			}
			else
				addColorTransform(transform);

			this.indices.push(prevNumberOfVertices + index);
			i++;
		}
	}

	public function addColoredTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint,
		?cameraBounds:FlxRect, ?transforms:Array<ColorTransform>)
	{
		if (position == null) position = point.set();
		cameraBounds?.putWeak(); // unused

		final prevNumberOfVertices = this.numVertices,
			verticesLength = (vertices.length >> 1) << 1,
			indicesLength = Math.floor(indices.length / 3) * 3;

		var i = 0;
		while (i < verticesLength) {
			this.uvtData.push(uvtData[i]);
			this.vertices.push(position.x + vertices[i]);
			this.uvtData.push(uvtData[++i]);
			this.vertices.push(position.y + vertices[i]);
			i++;
		}
		position.putWeak();

		final colorsLength = colors?.length ?? 0, transformsLength = transforms?.length ?? 0;
		var index = 0, color:FlxColor, transform:ColorTransform;

		i = 0;
		while (i < indicesLength) {
			if ((index = indices[i]) < transformsLength) transform = transforms[index];
			else transform = FlxDrawBaseItem.colorIdentity;

			if (index < colorsLength) {
				color = colors[index];
				if (colored) {
					colorMultipliers.push(transform.redMultiplier * color.redFloat);
					colorMultipliers.push(transform.greenMultiplier * color.greenFloat);
					colorMultipliers.push(transform.blueMultiplier * color.blueFloat);
					colorMultipliers.push(transform.alphaMultiplier * color.alphaFloat);
				}
				else
					alphas.push(transform.alphaMultiplier * color.alphaFloat);

				if (hasColorOffsets) {
					colorOffsets.push(transform.redOffset);
					colorOffsets.push(transform.greenOffset);
					colorOffsets.push(transform.blueOffset);
					colorOffsets.push(transform.alphaOffset);
				}
			}
			else
				addColorTransform(transform);

			this.indices.push(prevNumberOfVertices + index);
			i++;
		}
	}

	override function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform) {
		final prevNumberOfVertices = numVertices;

		inline function addVertex(x:Float, y:Float) {
			vertices.push(point.set(x, y).transform(matrix).x);
			vertices.push(point.y);
		}

		addVertex(0, 0);
		addVertex(frame.frame.width, 0);
		addVertex(frame.frame.width, frame.frame.height);
		addVertex(0, frame.frame.height);

		uvtData.push(frame.uv.left); uvtData.push(frame.uv.top);
		uvtData.push(frame.uv.right); uvtData.push(frame.uv.top);
		uvtData.push(frame.uv.right); uvtData.push(frame.uv.bottom);
		uvtData.push(frame.uv.left); uvtData.push(frame.uv.bottom);

		indices.push(prevNumberOfVertices);
		indices.push(prevNumberOfVertices + 1);
		indices.push(prevNumberOfVertices + 2);
		indices.push(prevNumberOfVertices + 2);
		indices.push(prevNumberOfVertices + 3);
		indices.push(prevNumberOfVertices);

		transform ??= FlxDrawBaseItem.colorIdentity;
		var vertices = INDICES_PER_QUAD;
		while (vertices-- > 0) {
			addColorTransform(transform);
		}
	}

	override function render(camera:FlxCamera) {
		//if (graphics.isDestroyed) throw 'Attempted to render an invalid FlxDrawTrianglesItem, did you destroy a cached sprite?';
		if (vertices.length == 0) return;

		final shader = shader ?? graphics.shader;
		bindToShader(camera, shader);
		//shader.frameRect.value = untyped (uvtData).__array;

		camera.canvas.graphics.drawTriangles(vertices, indices, uvtData, culling);
		camera.canvas.graphics.endFill();

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug) {
			camera.debugLayer.graphics.lineStyle(1, FlxColor.BLUE, 0.5);
			camera.debugLayer.graphics.drawTriangles(vertices, indices, uvtData);
		}
		#end

		FlxDrawBaseItem.drawCalls++;
	}

	override function get_numVertices():Int return vertices.length >> 1;
	override function get_numTriangles():Int return Math.floor(indices.length / 3);
}