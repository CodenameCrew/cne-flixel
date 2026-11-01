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
	static final bounds:FlxRect = FlxRect.get();
	static final colorTransform:ColorTransform = new ColorTransform();

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
	@:deprecated("verticesPosition is deprecated in flixel-funkin")
	public var verticesPosition:Int = 0;
	@:deprecated("indicesPosition is deprecated in flixel-funkin")
	public var indicesPosition:Int = 0;
	@:deprecated("colorsPosition is deprecated")
	public var colorsPosition:Int = 0;
	@:deprecated("colors is deprecated, use colorMultipliers and colorOffsets")
	public var colors:DrawData<Int> = new DrawData<Int>();

	public var culling:TriangleCulling = NONE;
	public var vertices:DrawData<Float> = new DrawData<Float>();
	public var indices:DrawData<Int> = new DrawData<Int>();
	public var uvtData:DrawData<Float> = new DrawData<Float>();

	#if !js
	var verticesArray:Array<Float>;
	var indicesArray:Array<Int>;
	var uvtDataArray:Array<Float>;
	#end

	var tempIndex3:Int;

	public function new() {
		super();
		type = TRIANGLES;

		#if !js
		@:privateAccess verticesArray = untyped (vertices).__array;
		@:privateAccess indicesArray = untyped (indices).__array;
		@:privateAccess uvtDataArray = untyped (uvtData).__array;
		#end
	}

	override function reset() {
		baseReset();

		//verticesPosition = 0;
		//indicesPosition = 0;
		//colorsPosition = 0;

		colors.length = 0;
		#if js
		vertices.length = 0;
		indices.length = 0;
		uvtData.length = 0;
		#else
		verticesArray.resize(0);
		indicesArray.resize(0);
		uvtDataArray.resize(0);
		#end
	}

	override function dispose() {
		baseDispose();

		colors.length = 0;
		vertices.length = 0;
		indices.length = 0;
		uvtData.length = 0;

		vertices = null;
		indices = null;
		uvtData = null;
		//colors = null;
	}

	public function addTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint,
		?cameraBounds:FlxRect, ?transform:ColorTransform)
	{
		if (position == null) position = point.set();
		cameraBounds?.putWeak(); // unused

		final prevNumVertices = this.numVertices,
			verticesLength = (vertices.length >> 1) << 1,
			indicesLength = Std.int(indices.length / 3) * 3;

		#if js
		tempIndex = 0;
		while (tempIndex < verticesLength) {
			this.uvtData.push(uvtData[tempIndex]);
			this.vertices.push(position.x + vertices[tempIndex++]);
			this.uvtData.push(uvtData[tempIndex]);
			this.vertices.push(position.y + vertices[tempIndex++]);
		}
		#else
		verticesArray.resize((tempIndex = verticesArray.length) + verticesLength);
		uvtDataArray.resize((tempIndex2 = uvtDataArray.length) + verticesLength);
		tempIndex3 = 0;
		while (tempIndex2 < verticesLength) {
			uvtDataArray[tempIndex2++] = uvtData[tempIndex3];
			verticesArray[tempIndex++] = position.x + vertices[tempIndex3++];
			uvtDataArray[tempIndex2++] = uvtData[tempIndex3];
			verticesArray[tempIndex++] = position.y + vertices[tempIndex3++];
		}
		#end

		position.putWeak();

		final colorsLength = colors?.length ?? 0;
		var i = 0, index:Int, color:FlxColor;

		if (colorsLength == 0) addColorTransform(transform, indicesLength);

		#if !js
		indicesArray.resize((tempIndex3 = indicesArray.length) + indicesLength);
		#end

		while (i < indicesLength) {
			if ((index = indices[i++]) < colorsLength) {
				color = colors[index];

				@:privateAccess colorTransform.__copyFrom(transform);
				colorTransform.redMultiplier *= color.redFloat;
				colorTransform.greenMultiplier *= color.greenFloat;
				colorTransform.blueMultiplier *= color.blueFloat;
				colorTransform.alphaMultiplier *= color.alphaFloat;

				addColorTransform(colorTransform);
			}
			else if (colorsLength != 0)
				addColorTransform(transform);

			#if js
			this.indices.push(prevNumVertices + index);
			#else
			indicesArray[tempIndex3++] = prevNumVertices + index;
			#end
		}
	}

	public function addColoredTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint,
		?cameraBounds:FlxRect, ?transforms:Array<ColorTransform>)
	{
		if (position == null) position = point.set();
		cameraBounds?.putWeak(); // unused

		final prevNumVertices = this.numVertices,
			verticesLength = (vertices.length >> 1) << 1,
			indicesLength = Std.int(indices.length / 3) * 3;

		#if js
		tempIndex = 0;
		while (tempIndex < verticesLength) {
			this.uvtData.push(uvtData[tempIndex]);
			this.vertices.push(position.x + vertices[tempIndex++]);
			this.uvtData.push(uvtData[tempIndex]);
			this.vertices.push(position.y + vertices[tempIndex++]);
		}
		#else
		verticesArray.resize((tempIndex = verticesArray.length) + verticesLength);
		uvtDataArray.resize((tempIndex2 = uvtDataArray.length) + verticesLength);
		tempIndex3 = 0;
		while (tempIndex2 < verticesLength) {
			uvtDataArray[tempIndex2++] = uvtData[tempIndex3];
			verticesArray[tempIndex++] = position.x + vertices[tempIndex3++];
			uvtDataArray[tempIndex2++] = uvtData[tempIndex3];
			verticesArray[tempIndex++] = position.y + vertices[tempIndex3++];
		}
		#end

		position.putWeak();

		final colorsLength = colors?.length ?? 0;
		var i = 0, index:Int, color:FlxColor;

		if (colorsLength == 0) addColorTransforms(transforms, indicesLength);

		#if !js
		indicesArray.resize((tempIndex3 = indicesArray.length) + indicesLength);
		#end

		while (i < indicesLength) {
			if ((index = indices[i++]) < colorsLength) {
				color = colors[index];

				@:privateAccess colorTransform.__copyFrom(transforms[index]);
				colorTransform.redMultiplier *= color.redFloat;
				colorTransform.greenMultiplier *= color.greenFloat;
				colorTransform.blueMultiplier *= color.blueFloat;
				colorTransform.alphaMultiplier *= color.alphaFloat;

				addColorTransform(colorTransform);
			}
			else if (colorsLength != 0)
				addColorTransform(transforms[index]);

			#if js
			this.indices.push(prevNumVertices + index);
			#else
			indicesArray[tempIndex3++] = prevNumVertices + index;
			#end
		}
	}

	override function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform) {
		final prevNumVertices = this.numVertices;

		#if !js
		verticesArray.resize((tempIndex = verticesArray.length) + 8);
		#end

		inline function addVertex(x:Float, y:Float) {
			#if js
			vertices.push(point.set(x, y).transform(matrix).x);
			vertices.push(point.y);
			#else
			vertices[tempIndex++] = point.set(x, y).transform(matrix).x;
			vertices[tempIndex++] = point.y;
			#end
		}

		addVertex(0, 0);
		addVertex(frame.frame.width, 0);
		addVertex(frame.frame.width, frame.frame.height);
		addVertex(0, frame.frame.height);

		#if js
		uvtData.push(frame.uv.left); uvtData.push(frame.uv.top);
		uvtData.push(frame.uv.right); uvtData.push(frame.uv.top);
		uvtData.push(frame.uv.right); uvtData.push(frame.uv.bottom);
		uvtData.push(frame.uv.left); uvtData.push(frame.uv.bottom);

		indices.push(prevNumVertices); indices.push(prevNumVertices + 1); indices.push(prevNumVertices + 2);
		indices.push(prevNumVertices + 2); indices.push(prevNumVertices + 3); indices.push(prevNumVertices);
		#else
		uvtDataArray.resize((tempIndex = uvtDataArray.length) + 8);
		uvtDataArray[tempIndex++] = frame.uv.left; uvtDataArray[tempIndex++] = frame.uv.top;
		uvtDataArray[tempIndex++] = frame.uv.right; uvtDataArray[tempIndex++] = frame.uv.top;
		uvtDataArray[tempIndex++] = frame.uv.right; uvtDataArray[tempIndex++] = frame.uv.bottom;
		uvtDataArray[tempIndex++] = frame.uv.left; uvtDataArray[tempIndex++] = frame.uv.bottom;

		indicesArray.resize((tempIndex = indicesArray.length) + 6);
		indicesArray[tempIndex++] = prevNumVertices; indicesArray[tempIndex++] = prevNumVertices + 1; indicesArray[tempIndex++] = prevNumVertices + 2;
		indicesArray[tempIndex++] = prevNumVertices + 2; indicesArray[tempIndex++] = prevNumVertices + 3; indicesArray[tempIndex++] = prevNumVertices;
		#end

		addColorTransform(transform, 6);
	}

	override function render(camera:FlxCamera) {
		//if (graphics.isDestroyed) throw 'Attempted to render an invalid FlxDrawTrianglesItem, did you destroy a cached sprite?';
		if (vertices.length == 0 || graphics.isDestroyed) return;

		final shader = shader ?? graphics.shader;
		bindToShader(camera, shader);

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
	override function get_numTriangles():Int return Std.int(indices.length / 3);
}