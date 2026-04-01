package flixel.math;

import flixel.util.FlxPool;
import flixel.util.FlxStringUtil;
import openfl.geom.Matrix;
import openfl.geom.Point;

/**
 * 2-dimensional point class
 * 
 * ## Pooling
 * To avoid creating new instances, unnecessarily, used points can be
 * for later use. Rather than creating a new instance directly, call
 * `FlxPoint.get(x, y)` and it will retrieve a point from the pool, if
 * one exists, otherwise it will create a new instance. Similarly, when
 * you're done using a point, call `myPoint.put()` to place it back.
 * 
 * You can disable point pooling entirely with `FLX_NO_POINT_POOL`.
 * 
 * ## Weak points
 * Weak points are points meant for a singular use, rather than calling
 * `put` on every point you `get`, you can create a weak point, and have
 * it placed back once used. All `FlxPoint` methods and Flixel utilities
 * automatically call `putWeak()` on every point passed in.
 * 
 * In the following example, a weak point is created, and passed into
 * `p.degreesTo` where `putWeak` is called on it, putting it back in the pool.
 *
 * ```haxe
 * var angle = p.degreesTo(FlxPoint.weak(FlxG.mouse.x, FlxG.mouse.y));
 * ```
 * 
 * ## Overloaded Operators
 * 
 * - `A += B` adds the value of `B` to `A`
 * - `A -= B` subtracts the value of `B` from `A`
 * - `A *= k` scales `A` by float `k` in both x and y components
 * - `A + B` returns a new point that is sum of `A` and `B`
 * - `A - B` returns a new point that is difference of `A` and `B`
 * - `A * k` returns a new point that is `A` scaled with coefficient `k`
 *
 * Note: also accepts `openfl.geom.Point`, but always returns a FlxPoint.
 *
 * Note: that these operators get points from the pool, but do not put
 * points back in the pool, unless they are weak.
 * 
 * Example: 4 total points are created, but only 3 are put into the pool
 * ```haxe
 * var a = FlxPoint.get(1, 1);
 * var b = FlxPoint.get(1, 1);
 * var c = (a * 2.0) + b;
 * a.put();
 * b.put();
 * c.put();
 * ```
 * 
 * To put all 4 back, it should look like this:
 * ```haxe
 * var a = FlxPoint.get(1, 1);
 * var b = FlxPoint.get(1, 1);
 * var c = a * 2.0;
 * var d = c + b;
 * a.put();
 * b.put();
 * c.put();
 * d.put();
 * ```
 * 
 * Otherwise, the remainging points will become garbage, adding to the
 * heap, potentially triggering a garbage collection when you don't want.
 */
@:forward abstract FlxPoint(FlxBasePoint) to FlxBasePoint from FlxBasePoint 
{
	/**
	 * Vector components less than this are considered zero, to account for rounding errors
	 */
	public static inline var EPSILON:Float = 0.0000001;
	public static inline var EPSILON_SQUARED:Float = EPSILON * EPSILON;

	/**
	 * Vector lengths less than this are considered zero, to account for rounding errors
	 */
	public static inline var EPSILON_LENGTH:Float = EPSILON * FlxMath.SQUARE_ROOT_OF_TWO;

	static var _point1 = FlxBasePoint._point1;

	// UNUSED
	static var _point2 = FlxBasePoint._point2;
	static var _point3 = FlxBasePoint._point3;

	/**
	 * Recycle or create new FlxPoint.
	 * Be sure to put() them back into the pool after you're done with them!
	 *
	 * @param   x  The X-coordinate of the point in space.
	 * @param   y  The Y-coordinate of the point in space.
	 */
	public static inline function get(x:Float = 0, y:Float = 0):FlxPoint return FlxBasePoint.get(x, y);

	/**
	 * Recycle or create a new FlxPoint which will automatically be released
	 * to the pool when passed into a flixel function.
	 *
	 * @param   x  The X-coordinate of the point in space.
	 * @param   y  The Y-coordinate of the point in space.
	 * @since 4.6.0
	 */
	public static inline function weak(x:Float = 0, y:Float = 0):FlxPoint return FlxBasePoint.weak(x, y);

	/**
	 * Operator that adds two points, returning a new point.
	 */
	@:noCompletion
	@:op(A + B)
	static inline function plusOp(a:FlxPoint, b:FlxPoint):FlxPoint {
		var result = get(a.x + b.x, a.y + b.y);
		a.putWeak();
		b.putWeak();
		return result;
	}

	/**
	 * Operator that subtracts two points, returning a new point.
	 */
	@:noCompletion
	@:op(A - B)
	static inline function minusOp(a:FlxPoint, b:FlxPoint):FlxPoint {
		var result = get(a.x - b.x, a.y - b.y);
		a.putWeak();
		b.putWeak();
		return result;
	}

	/**
	 * Operator that scales a point by float, returning a new point.
	 */
	@:noCompletion
	@:op(A * B)
	@:commutative
	static inline function scaleOp(a:FlxPoint, b:Float):FlxPoint {
		var result = get(a.x * b, a.y * b);
		a.putWeak();
		return result;
	}

	
	/**
	 * Operator that divides a point by float, returning a new point.
	 */
	@:noCompletion
	@:op(A / B)
	static inline function divideOp(a:FlxPoint, b:Float):FlxPoint {
		var result = get(a.x / b, a.y / b);
		a.putWeak();
		return result;
	}

	/**
	 * Operator that adds the right point to the left point, returning the left point instance.
	 */
	@:noCompletion
	@:op(A += B)
	static inline function plusEqualOp(a:FlxPoint, b:FlxPoint):FlxPoint
		return a.add(b);

	/**
	 * Operator that subtracts the right point from the left point, returning the left point instance.
	 */
	@:noCompletion
	@:op(A -= B)
	static inline function minusEqualOp(a:FlxPoint, b:FlxPoint):FlxPoint
		return a.subtract(b);

	/**
	 * Operator that scales a point by float, returning the same point instance.
	 */
	@:noCompletion
	@:op(A *= B)
	static inline function scaleEqualOp(a:FlxPoint, b:Float):FlxPoint
		return a.scale(b);


	/**
	 * Operator that adds two points, returning a new point.
	 */
	@:noCompletion
	@:op(A + B)
	@:commutative
	static inline function plusFlashOp(a:FlxPoint, b:Point):FlxPoint {
		var result = get(a.x + b.x, a.y + b.y);
		a.putWeak();
		return result;
	}

	/**
	 * Operator that subtracts two points, returning a new point.
	 */
	@:noCompletion
	@:op(A - B)
	static inline function minusFlashOp(a:FlxPoint, b:Point):FlxPoint {
		var result = get(a.x - b.x, a.y - b.y);
		a.putWeak();
		return result;
	}

	/**
	 * Operator that subtracts two points, returning a new point.
	 */
	@:noCompletion
	@:op(A - B)
	static inline function minusFlashOp2(a:Point, b:FlxPoint):FlxPoint {
		var result = get(a.x - b.x, a.y - b.y);
		b.putWeak();
		return result;
	}

	/**
	 * Operator that adds the right point to the left point, returning the left point instance.
	 */
	@:noCompletion
	@:op(A += B)
	static inline function plusEqualFlashOp(a:FlxPoint, b:Point):FlxPoint
		return a.add(b.x, b.y);

	/**
	 * Operator that subtracts the right point from the left point, returning the left point instance.
	 */
	@:noCompletion
	@:op(A -= B)
	static inline function minusEqualFlashOp(a:FlxPoint, b:Point):FlxPoint
		return a.subtract(b.x, b.y);


	public var x(get, set):Float;
	inline function get_x():Float return this.x;
	inline function set_x(x:Float):Float return this.x = x;

	public var y(get, set):Float;
	inline function get_y():Float return this.y;
	inline function set_y(y:Float):Float return this.y = y;

	/**
	 * The horizontal component of the unit point
	 */
	public var dx(get, never):Float; inline function get_dx():Float return this.dx;

	/**
	 * The vertical component of the unit point
	 */
	public var dy(get, never):Float; inline function get_dy():Float return this.dy;

	/**
	 * Length of the point
	 */
	public var length(get, set):Float;
	inline function get_length():Float return this.length;
	inline function set_length(l:Float):Float return this.length = l;

	/**
	 * length of the point squared
	 */
	public var lengthSquared(get, never):Float; inline function get_lengthSquared():Float return this.lengthSquared;

	/**
	 * The angle formed by the point with the horizontal axis (in degrees)
	 */
	public var degrees(get, set):Float;
	inline function get_degrees():Float return this.degrees;
	inline function set_degrees(degs:Float):Float return this.degrees = degs;

	/**
	 * The angle formed by the point with the horizontal axis (in radians)
	 */
	public var radians(get, set):Float;
	inline function get_radians():Float return this.radians;
	inline function set_radians(rads:Float):Float return this.radians = rads;

	/**
	 * The horizontal component of the right normal of the point
	 */
	public var rx(get, never):Float; inline function get_rx():Float return this.rx;

	/**
	 * The vertical component of the right normal of the point
	 */
	public var ry(get, never):Float; inline function get_ry():Float return this.ry;

	/**
	 * The horizontal component of the left normal of the point
	 */
	public var lx(get, never):Float; inline function get_lx():Float return this.lx;

	/**
	 * The vertical component of the left normal of the point
	 */
	public var ly(get, never):Float; inline function get_ly():Float return this.ly;

	public inline function new(x:Float = 0, y:Float = 0)
		this = FlxPoint.get(x, y);
	
	/**
	 * Set the coordinates of this point object.
	 *
	 * @param   n  The X and Y coordinate of the point in space.
	 */
	public inline function setXY(n:Float):FlxPoint return this.setXY(n);

	/**
	 * Set the coordinates of this point object.
	 *
	 * @param   x  The X-coordinate of the point in space.
	 * @param   y  The Y-coordinate of the point in space.
	 */
	public inline function set(?x:Float, ?y:Float):FlxPoint return this.set(x, y);

	/**
	 * Adds to the coordinates of this point.
	 *
	 * @param   x  Amount to add to x
	 * @param   y  Amount to add to y
	 * @return  This point.
	 */
	public overload extern inline function add(?x:Float, ?y:Float):FlxPoint return this.add(x, y);

	/**
	 * Adds the coordinates of another point to the coordinates of this point.
	 * @since 6.0.0
	 *
	 * @param   point  The point to add to this point
	 * @return  This point.
	 */
	public overload inline extern function add(point:FlxPoint):FlxPoint return this.addPoint(point);

	/**
	 * Adds the coordinates of another point to the coordinates of this point.
	 * @since 6.0.0
	 *
	 * @param   p  Any Point.
	 * @return  A reference to the altered point parameter.
	 */
	public overload inline extern function add(p:Point):FlxPoint return this.add(p.x, p.y);

	/**
	 * Adds the coordinates of another point to the coordinates of this point.
	 *
	 * @param   point  The point to add to this point
	 * @return  This point.
	 */
	public inline function addPoint(point:FlxPoint):FlxPoint return this.addPoint(point);

	/**
	 * Helper function.
	 *
	 * @param   p  Any Point.
	 * @return  This point.
	 */
	public inline function addFromFlash(p:Point):FlxPoint return this.add(p.x, p.y);

	/**
	 * Helper function, just increases the values of the specified Flash point by the values of this point.
	 *
	 * @param   p  Any Point.
	 * @return  A reference to the altered point parameter.
	 */
	public inline function addToFlash(p:Point):Point return this.addToFlash(p);


	/**
	 * Return new point which equals to sum of this point and passed p point.
	 *
	 * @param   p  point to add
	 * @return  addition result
	 */
	public inline function addNew(p:FlxPoint):FlxPoint return this.copyTo().addPoint(p);

	/**
	 * Subtracts from the coordinates of this point.
	 *
	 * @param   x  Amount to subtract from x
	 * @param   y  Amount to subtract from y
	 * @return  This point.
	 */
	public overload inline extern function subtract(?x:Float, ?y:Float):FlxPoint return this.subtract(x, y);

	/**
	 * Subtracts the coordinates of another point from the coordinates of this point.
	 * @since 6.0.0
	 *
	 * @param   point  The point to subtract from this point
	 * @return  This point.
	 */
	public overload inline extern function subtract(point:FlxPoint):FlxPoint return this.subtractPoint(point);

	/**
	 * Subtracts the coordinates of another point from the coordinates of this point.
	 * @since 6.0.0
	 *
	 * @param   point  The point to subtract from this point
	 * @return  This point.
	 */
	public overload inline extern function subtract(point:Point):FlxPoint return this.subtract(point.x, point.y);

	/**
	 * Subtracts the coordinates of another point from the coordinates of this point.
	 *
	 * @param   point  The point to subtract from this point
	 * @return  This point.
	 */
	public inline function subtractPoint(point:FlxPoint):FlxPoint return this.subtractPoint(point);

	/**
	 * Helper function.
	 *
	 * @param   p  Any Point.
	 * @return  This point.
	 */
	public inline function subtractFromFlash(p:Point):FlxPoint return this.subtract(p.x, p.y);

	/**
	 * Helper function, just decreases the values of the specified Flash point by the values of this point.
	 *
	 * @param   p  Any Point.
	 * @return  A reference to the altered point parameter.
	 */
	public inline function subtractToFlash(p:Point):Point return this.subtractToFlash(p);

	/**
	 * Returns new point which is result of subtraction of p point from this point.
	 *
	 * @param   p  point to subtract
	 * @return  subtraction result
	 */
	public inline function subtractNew(p:FlxPoint):FlxPoint return this.copyTo().subtractPoint(p);

	/**
	 * Scale this point.
	 *
	 * @param   x  The x scale coefficient
	 * @param   y  The y scale coefficient
	 * @return  this point
	 */
	public overload inline extern function scale(x:Float, y:Float):FlxPoint return this.scale(x, y);

	/**
	 * Scale this point.
	 * @since 6.0.0
	 *
	 * @param   amount  The scale coefficient
	 * @return  this point
	 */
	public overload inline extern function scale(amount:Float):FlxPoint return this.scale(amount, amount);

	/**
	 * Scale this point by another point.
	 * @since 6.0.0
	 *
	 * @param   point  The x and y scale coefficient
	 * @return  this point
	 */
	public overload inline extern function scale(point:FlxPoint):FlxPoint return this.scalePoint(point);

	/**
	 * Scale this point by another point.
	 * @since 6.0.0
	 *
	 * @param   point  The x and y scale coefficient
	 * @return  this point
	 */
	public overload inline extern function scale(point:Point):FlxPoint return this.scale(point.x, point.y);

	/**
	 * Scale this point by another point.
	 *
	 * @param   point  The x and y scale coefficient
	 * @return  scaled point
	 */
	public inline function scalePoint(point:FlxPoint):FlxPoint return this.scalePoint(point);

	/**
	 * Helper function.
	 *
	 * @param   p  Any Point.
	 * @return  This point.
	 */
	public inline function scaleFromFlash(p:Point):FlxPoint return this.scale(p.x, p.y);

	/**
	 * Helper function.
	 *
	 * @param   p  Any Point.
	 * @return  A reference to the altered point parameter.
	 */
	public inline function scaleToFlash(p:Point):Point return this.scaleToFlash(p);

	/**
	 * Returns scaled copy of this point.
	 *
	 * @param   k - scale coefficient
	 * @return  scaled point
	 */
	public inline function scaleNew(k:Float):FlxPoint return this.copyTo().scale(k, k);

	/**
	 * Helper function, just copies the values from the specified point.
	 *
	 * @param   p  Any FlxPoint.
	 * @return  A reference to itself.
	 */
	public overload inline extern function copyFrom(p:FlxPoint):FlxPoint return this.copyFrom(p);

	/**
	 * Helper function, just copies the values from the specified Flash point.
	 * @since 6.0.0
	 *
	 * @param   p  Any Point.
	 * @return  A reference to itself.
	 */
	public overload inline extern function copyFrom(p:Point):FlxPoint return this.copyFromFlash(p);

	/**
	 * Helper function, just copies the values from the specified Flash point.
	 *
	 * @param   p  Any Point.
	 * @return  A reference to itself.
	 */
	public inline function copyFromFlash(p:Point):FlxPoint return this.copyFromFlash(p);

	/**
	 * Helper function, just copies the values from this point to the specified point.
	 *
	 * @param   p  An optional point to copy this point to
	 * @return  The new point
	 */
	public overload inline extern function copyTo(?p:FlxPoint):FlxPoint return this.copyTo(p);

	/**
	 * Helper function, just copies the values from this point to the specified Flash point.
	 * @since 6.0.0
	 *
	 * @param   p  The point to copy this point to
	 * @return  The new point
	 */
	public overload inline extern function copyTo(p:Point):Point return this.copyToFlash(p);

	/**
	 * Helper function, just copies the values from this point to the specified Flash point.
	 *
	 * @param   p  Any Point.
	 * @return  A reference to the altered point parameter.
	 */
	public inline function copyToFlash(?p:Point):Point return this.copyToFlash(p);

	/**
	 * Rounds x and y using Math.floor()
	 */
	public inline function floor():FlxPoint return this.floor();

	/**
	 * Rounds x and y using Math.ceil()
	 */
	public inline function ceil():FlxPoint return this.ceil();

	/**
	 * Rounds x and y using Math.round()
	 */
	public inline function round():FlxPoint return this.round();

	/**
	 * Returns true if this point is within the given rectangular bounds
	 *
	 * @param	x       The X value of the region to test within
	 * @param	y       The Y value of the region to test within
	 * @param	width   The width of the region to test within
	 * @param	height  The height of the region to test within
	 * @return	True if the point is within the region, otherwise false
	 */
	public inline function inCoords(x:Float, y:Float, width:Float, height:Float):Bool return this.inCoords(x, y, width, height);

	/**
	 * Returns true if this point is within the given rectangular block
	 *
	 * @param	rect	The FlxRect to test within
	 * @return	True if pointX/pointY is within the FlxRect, otherwise false
	 */
	public inline function inRect(rect:FlxRect):Bool return this.inRect(rect);

	/**
	 * Rotates this point clockwise in 2D space around another point by the given radians.
	 * Note: To rotate a point around 0,0 you can use `p.radians += angle`
	 * @since 5.0.0
	 *
	 * @param   pivot    The pivot you want to rotate this point around
	 * @param   radians  Rotate the point by this many radians clockwise.
	 * @return  A FlxPoint containing the coordinates of the rotated point.
	 */
	public inline function pivotRadians(pivot:FlxPoint, radians:Float):FlxPoint return this.pivotRadians(pivot, radians);

	/**
	 * Rotates this point clockwise in 2D space around another point by the given degrees.
	 * Note: To rotate a point around 0,0 you can use `p.degrees += angle`
	 * @since 5.0.0
	 *
	 * @param   pivot    The pivot you want to rotate this point around
	 * @param   degrees  Rotate the point by this many degrees clockwise.
	 * @return  A FlxPoint containing the coordinates of the rotated point.
	 */
	public inline function pivotDegrees(pivot:FlxPoint, degrees:Float):FlxPoint return this.pivotRadians(pivot, degrees * FlxAngle.TO_RAD);

	/**
	 * Calculate the distance to another point.
	 *
	 * @param   point  A FlxPoint object to calculate the distance to.
	 * @return  The distance between the two points as a Float.
	 */
	public overload inline extern function distanceTo(point:FlxPoint):Float return this.distanceToPoint(point);

	/**
	 * Calculate the distance to another position
	 * @since 6.0.0
	 *
	 * @return  The distance between the two positions as a Float.
	 */
	public overload inline extern function distanceTo(x:Float, y:Float):Float return this.distanceTo(x, y);
	
	/**
	 * Calculate the squared distance to another point.
	 * @since 6.0.0
	 *
	 * @param   point  A FlxPoint object to calculate the distance to.
	 * @return  The distance between the two points as a Float.
	 */
	public overload inline extern function distanceSquaredTo(point:FlxPoint):Float return this.distanceSquaredToPoint(point);
	
	/**
	 * Calculate the distance to another position
	 * @since 6.0.0
	 *
	 * @return  The distance between the two positions as a Float.
	 */
	public overload inline extern function distanceSquaredTo(x:Float, y:Float):Float return this.distanceSquaredTo(x, y);

	/**
	 * Calculates the angle from this to another point.
	 * If the point is straight right of this, 0 is returned.
	 * @since 5.0.0
	 *
	 * @param   point  The other point.
	 * @return  The angle, in radians, between -PI and PI
	 */
	public inline function radiansTo(point:FlxPoint):Float return this.radiansTo(point);

	/**
	 * Calculates the angle from another point to this.
	 * If this is straight right of the point, 0 is returned.
	 * @since 5.0.0
	 *
	 * @param   point  The other point.
	 * @return  The angle, in radians, between -PI and PI
	 */
	public inline function radiansFrom(point:FlxPoint):Float return point.radiansTo(this);

	/**
	 * Calculates the angle from this to another point.
	 * If the point is straight right of this, 0 is returned.
	 * @since 5.0.0
	 *
	 * @param   point  The other point.
	 * @return  The angle, in degrees, between -180 and 180
	 */
	public inline function degreesTo(point:FlxPoint):Float return this.degreesTo(point);

	/**
	 * Calculates the angle from another point to this.
	 * If this is straight right of the point, 0 is returned.
	 * @since 5.0.0
	 *
	 * @param   point  The other point.
	 * @return  The angle, in degrees, between -180 and 180
	 */
	public inline function degreesFrom(point:FlxPoint):Float return point.degreesTo(this);

	/**
	 * Applies transformation matrix to this point
	 * @param   matrix  transformation matrix
	 * @return  transformed point
	 */
	public inline function transform(matrix:Matrix):FlxPoint return this.transform(matrix);

	/**
	 * Short for dot product.
	 *
	 * @param   p  point to multiply
	 * @return  dot product of two points
	 */
	public inline function dot(p:FlxPoint):Float return this.dotProduct(p);

	/**
	 * Dot product between two points.
	 *
	 * @param   p  point to multiply
	 * @return  dot product of two points
	 */
	public inline function dotProduct(p:FlxPoint):Float return this.dotProduct(p);

	/**
	 * Dot product between two points.
	 * Meant for internal use, does not call putWeak.
	 *
	 * @param   p  point to multiply
	 * @return  dot product of two points
	 */
	public inline function dotProductWeak(p:FlxPoint):Float return this.dotProductXY(p.x, p.y);

	public inline function dotProductXY(x:Float, y:Float):Float return this.dotProductXY(x, y);

	/**
	 * Dot product of points with normalization of the second point.
	 *
	 * @param   p  point to multiply
	 * @return  dot product of two points
	 */
	public inline function dotProdWithNormalizing(p:FlxPoint):Float return this.dotProdWithNormalizing(p);

	/**
	 * Check the perpendicularity of two points.
	 *
	 * @param   p  point to check
	 * @return  true - if they are perpendicular
	 */
	public inline function isPerpendicular(p:FlxPoint):Bool return this.isPerpendicular(p);

	/**
	 * Find the length of cross product between two points.
	 *
	 * @param   p  point to multiply
	 * @return  the length of cross product of two points
	 */
	public inline function crossProductLength(p:FlxPoint):Float return this.crossProductLength(p);

	/**
	 * Find the length of cross product between two points.
	 * Meant for internal use, does not call putWeak.
	 *
	 * @param   p  point to multiply
	 * @return  the length of cross product of two points
	 */
	public inline function crossProductLengthWeak(p:FlxPoint):Float return this.crossProductLengthWeak(p);

	/**
	 * Check for parallelism of two points.
	 *
	 * @param   p  point to check
	 * @return  true - if they are parallel
	 */
	public inline function isParallel(p:FlxPoint):Bool return this.isParallel(p);

	/**
	 * Check for parallelism of two points.
	 * Meant for internal use, does not call putWeak.
	 *
	 * @param   p  point to check
	 * @return  true - if they are parallel
	 */
	public inline function isParallelWeak(p:FlxPoint):Bool return this.isParallelWeak(p);

	/**
	 * Check if this point has zero length.
	 *
	 * @return  true - if the point is zero
	 */
	public inline function isZero():Bool return this.isZero();

	/**
	 * point reset
	 */
	public inline function zero():FlxPoint return this.zero();

	/**
	 * Normalization of the point (reduction to unit length)
	 */
	public inline function normalize():FlxPoint return this.normalize();

	/**
	 * Check the point for unit length
	 */
	public inline function isNormalized():Bool return this.isNormalized();

	/**
	 * Rotate the point for a given angle.
	 *
	 * @param   rads  angle to rotate
	 * @return  rotated point
	 */
	public inline function rotateByRadians(rads:Float):FlxPoint return this.rotateByRadians(rads);

	/**
	 * Rotate the point for a given angle.
	 *
	 * @param   degs  angle to rotate
	 * @return  rotated point
	 */
	public inline function rotateByDegrees(degs:Float):FlxPoint return this.rotateByRadians(degs * FlxAngle.TO_RAD);

	/**
	 * Rotate the point with the values of sine and cosine of the angle of rotation.
	 *
	 * @param   sin  the value of sine of the angle of rotation
	 * @param   cos  the value of cosine of the angle of rotation
	 * @return  rotated point
	 */
	public inline function rotateWithTrig(sin:Float, cos:Float):FlxPoint return this.set(x * cos - y * sin, x * sin + y * cos);

	/**
	 * Sets the polar coordinates of the point
	 *
	 * @param   length   The length to set the point
	 * @param   radians  The angle to set the point, in radians
	 * @return  The rotated point
	 * 
	 * @since 4.10.0
	 */
	public function setPolarRadians(length:Float, radians:Float):FlxPoint return this.setPolarRadians(length, radians);

	/**
	 * Sets the polar coordinates of the point
	 *
	 * @param   length  The length to set the point
	 * @param   degrees The angle to set the point, in degrees
	 * @return  The rotated point
	 * 
	 * @since 4.10.0
	 */
	public inline function setPolarDegrees(length:Float, degrees:Float):FlxPoint return this.setPolarDegrees(length, degrees);

	/**
	 * Right normal of the point
	 */
	public inline function rightNormal(?p:FlxPoint):FlxPoint return p == null ? get(rx, ry) : p.set(rx, ry);

	/**
	 * Left normal of the point
	 */
	public inline function leftNormal(?p:FlxPoint):FlxPoint return p == null ? get(lx, ly) : p.set(lx, ly);

	/**
	 * Change direction of the point to opposite
	 */
	public inline function negate():FlxPoint return set(-x, -y);

	public inline function negateNew(?result:FlxPoint):FlxPoint return this.copyTo(result).set(-x, -y);

	/**
	 * The projection of this point to point that is passed as an argument
	 * (without modifying the original point!).
	 *
	 * @param   p     point to project
	 * @param   proj  optional argument - result point
	 * @return  projection of the point
	 */
	public inline function projectTo(p:FlxPoint, ?proj:FlxPoint):FlxPoint return this.projectTo(p, proj);

	/**
	 * Projecting this point on the normalized point p.
	 *
	 * @param   p     this point has to be normalized, ie have unit length
	 * @param   proj  optional argument - result point
	 * @return  projection of the point
	 */
	public inline function projectToNormalized(p:FlxPoint, ?proj:FlxPoint):FlxPoint return this.projectToNormalized(p, proj);

	/**
	 * Projecting this point on the normalized point p.
	 * Meant for internal use, does not call putWeak.
	 *
	 * @param   p     this point has to be normalized, ie have unit length
	 * @param   proj  optional argument - result point
	 * @return  projection of the point
	 */
	public inline function projectToNormalizedWeak(p:FlxPoint, ?proj:FlxPoint):FlxPoint return this.projectToNormalizedWeak(p, proj);

	/**
	 * Dot product of left the normal point and point p.
	 */
	public inline function perpProduct(p:FlxPoint):Float return this.perpProduct(p);

	/**
	 * Dot product of left the normal point and point p.
	 * Meant for internal use, does not call putWeak.
	 */
	public inline function perpProductWeak(p:FlxPoint):Float return this.perpProductXY(p.x, p.y);

	public inline function perpProductXY(x:Float, y:Float):Float return this.perpProductXY(x, y);

	/**
	 * Find the ratio between the perpProducts of this point and p point. This helps to find the intersection point.
	 *
	 * @param   a  start point of the point
	 * @param   b  start point of the p point
	 * @param   p  the second point
	 * @return  the ratio between the perpProducts of this point and p point
	 */
	public inline function ratio(a:FlxPoint, b:FlxPoint, p:FlxPoint):Float return this.ratio(a, b, p);

	/**
	 * Find the ratio between the perpProducts of this point and p point. This helps to find the intersection point.
	 * Meant for internal use, does not call putWeak.
	 *
	 * @param   a  start point of the point
	 * @param   b  start point of the p point
	 * @param   p  the second point
	 * @return  the ratio between the perpProducts of this point and p point
	 */
	public inline function ratioWeak(a:FlxPoint, b:FlxPoint, p:FlxPoint):Float return this.ratioWeak(a, b, p);

	/**
	 * Finding the point of intersection of points.
	 *
	 * @param   a  start point of the point
	 * @param   b  start point of the p point
	 * @param   p  the second point
	 * @return the point of intersection of points
	 */
	public inline function findIntersection(a:FlxPoint, b:FlxPoint, p:FlxPoint, ?intersection:FlxPoint):FlxPoint
		return this.findIntersection(a, b, p, intersection);

	/**
	 * Finding the point of intersection of points if it is in the "bounds" of the points.
	 *
	 * @param   a   start point of the point
	 * @param   b   start point of the p point
	 * @param   p   the second point
	 * @return the point of intersection of points if it is in the "bounds" of the points
	 */
	public inline function findIntersectionInBounds(a:FlxPoint, b:FlxPoint, p:FlxPoint, ?intersection:FlxPoint):FlxPoint
		return this.findIntersectionInBounds(a, b, p, intersection);

	/**
	 * Limit the length of this point.
	 *
	 * @param   max  maximum length of this point
	 */
	public inline function truncate(max:Float):FlxPoint return this.truncate(max);

	/**
	 * Get the angle between points (in radians).
	 *
	 * @param   p   second point, which we find the angle
	 * @return  the angle in radians
	 */
	public inline function radiansBetween(p:FlxPoint):Float return this.radiansBetween(p);

	/**
	 * The angle between points (in degrees).
	 *
	 * @param   p   second point, which we find the angle
	 * @return  the angle in degrees
	 */
	public inline function degreesBetween(p:FlxPoint):Float return this.radiansBetween(p) * FlxAngle.TO_DEG;

	/**
	 * The sign of half-plane of point with respect to the point through the a and b points.
	 *
	 * @param   a  start point of the wall-point
	 * @param   b  end point of the wall-point
	 */
	public function sign(a:FlxPoint, b:FlxPoint):Int return this.sign(a, b);

	/**
	 * The distance between points
	 * @since 6.0.0
	 */
	public overload inline extern function dist(x:Float, y:Float):Float return this.distanceTo(x, y);

	/**
	 * The distance between points
	 */
	public overload inline extern function dist(p:FlxPoint):Float return this.distanceToPoint(p);
	
	/**
	 * The squared distance between points
	 */
	public overload inline extern function distSquared(p:FlxPoint):Float return this.distanceSquaredToPoint(p);
	
	/**
	 * The squared distance between positions
	 * @since 6.0.0
	 */
	public overload inline extern function distSquared(x:Float, y:Float):Float return this.distanceSquaredTo(x, y);

	/**
	 * Reflect the point with respect to the normal of the "wall".
	 *
	 * @param   normal      left normal of the "wall". It must be normalized (no checks)
	 * @param   bounceCoeff bounce coefficient (0 <= bounceCoeff <= 1)
	 * @return  reflected point (angle of incidence equals to angle of reflection)
	 */
	public inline function bounce(normal:FlxPoint, ?bounceCoeff:Float):FlxPoint return this.bounce(normal, bounceCoeff);

	/**
	 * Reflect the point with respect to the normal. This operation takes "friction" into account.
	 *
	 * @param   normal      left normal of the "wall". It must be normalized (no checks)
	 * @param   bounceCoeff bounce coefficient (0 <= bounceCoeff <= 1)
	 * @param   friction    friction coefficient
	 * @return  reflected point
	 */
	public inline function bounceWithFriction(normal:FlxPoint, ?bounceCoeff:Float, ?friction:Float):FlxPoint
		return this.bounceWithFriction(normal, bounceCoeff, friction);

	/**
	 * Checking if this is a valid point.
	 *
	 * @return  true - if the point is valid
	 */
	public inline function isValid():Bool return this.isValid();

	/**
	 * Copies this point.
	 *
	 * @param   p  An optional point to copy this point to
	 * @return  The new point
	 */
	public inline function clone(?p:FlxPoint):FlxPoint return this.copyTo(p);
}

/**
 * The base class of FlxPoint, just use FlxPoint instead.
 * 
 * Note to contributors: don't worry about adding functionality to the base class.
 * it's all mostly inlined anyway so there's no runtime definitions for
 * reflection or anything.
 */
@:noCompletion
@:noDoc
@:allow(flixel.math.FlxPoint)
class FlxBasePoint implements IFlxPooled
{
	/* Reflections from FlxPoint */
	public static var EPSILON:Float = 0.0000001;
	public static var EPSILON_SQUARED:Float = FlxPoint.EPSILON * FlxPoint.EPSILON;

	public static var EPSILON_LENGTH:Float = FlxPoint.EPSILON * FlxMath.SQUARE_ROOT_OF_TWO;

	#if FLX_POINT_POOL
	static var pool:FlxPool<FlxBasePoint> = new FlxPool(FlxBasePoint.new.bind(0, 0));
	#end

	static var _point1 = new FlxPoint();

	// UNUSED
	static var _point2 = new FlxPoint();
	static var _point3 = new FlxPoint();

	/**
	 * Recycle or create a new FlxBasePoint.
	 * Be sure to put() them back into the pool after you're done with them!
	 *
	 * @param   x  The X-coordinate of the point in space.
	 * @param   y  The Y-coordinate of the point in space.
	 * @return  This point.
	 */
	public static inline function get(x:Float = 0, y:Float = 0):FlxBasePoint {
		#if FLX_POINT_POOL
		var point = pool.get().set(x, y);
		point._inPool = false;
		return point;
		#else
		return new FlxBasePoint(x, y);
		#end
	}

	/**
	 * Recycle or create a new FlxBasePoint which will automatically be released
	 * to the pool when passed into a flixel function.
	 *
	 * @param   x  The X-coordinate of the point in space.
	 * @param   y  The Y-coordinate of the point in space.
	 * @return  This point.
	 */
	public static inline function weak(x:Float = 0, y:Float = 0):FlxBasePoint {
		var point = get(x, y);
		#if FLX_POINT_POOL
		point._weak = true;
		#end
		return point;
	}

	public var x(default, set):Float = 0; function set_x(x:Float):Float return this.x = x;
	public var y(default, set):Float = 0; function set_y(y:Float):Float return this.y = y;


	/* Reflections from FlxPoint */
	public var dx(get, never):Float; inline function get_dx():Float return isZero() ? 0 : x / length;
	public var dy(get, never):Float; inline function get_dy():Float return isZero() ? 0 : y / length;
	public var length(get, set):Float;
	inline function get_length():Float return Math.sqrt(lengthSquared);
	inline function set_length(l:Float):Float {
		if (!isZero()) {
			final a = radians;
			set(l * Math.cos(a), l * Math.sin(a));
		}
		return l;
	}

	public var lengthSquared(get, never):Float; inline function get_lengthSquared():Float return x * x + y * y;
	public var degrees(get, set):Float;
	inline function get_degrees():Float return radians * FlxAngle.TO_DEG;
	inline function set_degrees(degs:Float):Float {
		radians = degs * FlxAngle.TO_RAD;
		return degs;
	}

	public var radians(get, set):Float;
	inline function get_radians():Float return FlxAngle.radiansFromOrigin(x, y);
	inline function set_radians(rads:Float):Float {
		if (!isZero()) {
			final len = length;
			set(len * Math.cos(rads), len * Math.sin(rads));
		}
		return rads;
	}

	public var rx(get, never):Float; inline function get_rx():Float return -y;
	public var ry(get, never):Float; inline function get_ry():Float return x;
	public var lx(get, never):Float; inline function get_lx():Float return y;
	public var ly(get, never):Float; inline function get_ly():Float return -x;

	#if FLX_POINT_POOL
	var _weak:Bool = false;
	var _inPool:Bool = false;
	#end

	@:keep
	public inline function new(x:Float = 0, y:Float = 0) set(x, y);
	
	/**
	 * Set the coordinates of this point object.
	 *
	 * @param   x  The X-coordinate of the point in space.
	 * @param   y  The Y-coordinate of the point in space.
	 */
	public function set(x:Float = 0, y:Float = 0):FlxBasePoint {
		this.x = x;
		this.y = y;
		return this;
	}
	
	/**
	 * Add this FlxBasePoint to the recycling pool.
	 */
	public function put():Void {
		#if FLX_POINT_POOL
		if (!_inPool) {
			_inPool = true;
			_weak = false;
			pool.putUnsafe(this);
		}
		#end
	}

	/**
	 * Add this FlxBasePoint to the recycling pool if it's a weak reference (allocated via weak()).
	 */
	public function putWeak():Void {
		#if FLX_POINT_POOL if (_weak) put(); #end
	}

	/**
	 * Function to compare this FlxBasePoint to another.
	 *
	 * @param   point  The other FlxBasePoint to compare to this one.
	 * @return  True if the FlxBasePoints have the same x and y value, false otherwise.
	 */
	public function equals(point:FlxBasePoint):Bool {
		var result = FlxMath.equal(x, point.x) && FlxMath.equal(y, point.y);
		point.putWeak();
		return result;
	}

	/**
	 * Necessary for IFlxDestroyable.
	 */
	public function destroy() {}

	/**
	 * Convert object to readable string name. Useful for debugging, save games, etc.
	 */
	public inline function toString():String
		return FlxStringUtil.getDebugString([LabelValuePair.weak("x", x), LabelValuePair.weak("y", y)]);


	/* Reflections from FlxPoint */
	public function setXY(n:Float):FlxBasePoint return set(n, n);

	public function add(x:Float = 0, y:Float = 0):FlxBasePoint return set(this.x + x, this.y + y);

	public function addPoint(p:FlxBasePoint):FlxBasePoint {
		add(p.x, p.y);
		p.putWeak();
		return this;
	}

	public function addFromFlash(p:Point):FlxBasePoint return add(p.x, p.y);

	public function addToFlash(p:Point):Point {
		p.x += x;
		p.y += y;
		return p;
	}

	public function subtract(x:Float = 0, y:Float = 0):FlxBasePoint return set(this.x - x, this.y - y);

	public function subtractPoint(p:FlxBasePoint):FlxBasePoint {
		subtract(p.x, p.y);
		p.putWeak();
		return this;
	}

	public function subtractFromFlash(p:Point):FlxBasePoint return subtract(p.x, p.y);

	public function subtractToFlash(p:Point):Point {
		p.x -= x;
		p.y -= y;
		return p;
	}

	public function scale(?x:Float, ?y:Float):FlxBasePoint
		return x == null ? set(this.x, this.y) : set(this.x * x, this.y * (y == null ? x : y));

	public function scalePoint(p:FlxBasePoint):FlxBasePoint {
		scale(p.x, p.y);
		p.putWeak();
		return this;
	}

	public function scaleFromFlash(p:Point):FlxBasePoint return scale(p.x, p.y);

	public function scaleToFlash(p:Point):Point {
		p.x *= x;
		p.y *= y;
		return p;
	}

	public function scaleNew(k:Float):FlxBasePoint return copyTo().scale(k, k);

	public function addNew(p:FlxBasePoint):FlxBasePoint return copyTo().add(p.x, p.y);

	public function subtractNew(p:FlxBasePoint):FlxBasePoint return copyTo().subtract(p.x, p.y);

	public function copyFrom(p:FlxBasePoint):FlxBasePoint {
		set(p.x, p.y);
		p.putWeak();
		return this;
	}

	public function copyFromFlash(p:Point):FlxBasePoint return set(p.x, p.y);

	public function copyTo(?p:FlxBasePoint):FlxBasePoint return p == null ? get(x, y) : p.set(x, y);

	public function copyToFlash(?p:Point):Point {
		if (p == null) p = new Point();
		p.x = x;
		p.y = y;
		return p;
	}

	public function floor():FlxBasePoint return set(Math.floor(x), Math.floor(y));

	public function ceil():FlxBasePoint return set(Math.ceil(x), Math.ceil(y));

	public function round():FlxBasePoint return set(Math.round(x), Math.round(y));

	public function inCoords(x:Float, y:Float, width:Float, height:Float):Bool
		return FlxMath.pointInCoordinates(this.x, this.y, x, y, width, height);

	public function inRect(rect:FlxRect):Bool
		return FlxMath.pointInFlxRect(x, y, rect);

	public function pivotRadians(pivot:FlxBasePoint, radians:Float):FlxBasePoint {
		_point1.copyFrom(this).subtract(pivot);
		_point1.radians += radians;
		set(_point1.x + pivot.x, _point1.y + pivot.y);
		pivot.putWeak();
		return this;
	}

	public function pivotDegrees(pivot:FlxBasePoint, degrees:Float):FlxBasePoint return pivotRadians(pivot, degrees * FlxAngle.TO_RAD);

	public function distanceTo(x:Float, y:Float):Float return Math.sqrt(distanceSquaredTo(x, y));

	public function distanceToPoint(point:FlxBasePoint):Float {
		final result = distanceTo(point.x, point.y);
		point.putWeak();
		return result;
	}

	public function distanceSquaredTo(x:Float, y:Float):Float
		return (this.x - x) * (this.x - x) + (this.y - y) * (this.y - y);

	public function distanceSquaredToPoint(point:FlxBasePoint):Float {
		final result = distanceSquaredTo(point.x, point.y);
		point.putWeak();
		return result;
	}

	public function radiansTo(point:FlxBasePoint):Float return FlxAngle.radiansFromOrigin(point.x - x, point.y - y);

	public function radiansFrom(point:FlxBasePoint):Float return point.radiansTo(this);

	public function degreesTo(point:FlxBasePoint):Float return FlxAngle.degreesFromOrigin(point.x - x, point.y - y);

	public function degreesFrom(point:FlxBasePoint):Float return point.degreesTo(this);

	public function transform(matrix:Matrix):FlxBasePoint {
		return set(
			x * matrix.a + y * matrix.c + matrix.tx,
			x * matrix.b + y * matrix.d + matrix.ty
		);
	}

	public function dot(p:FlxBasePoint):Float return dotProduct(p);

	public function dotProduct(p:FlxBasePoint):Float {
		var dp = dotProductXY(p.x, p.y);
		p.putWeak();
		return dp;
	}

	function dotProductWeak(p:FlxBasePoint):Float return dotProductXY(p.x, p.y);

	function dotProductXY(x:Float, y:Float):Float return this.x * x + this.y * y;

	public function dotProdWithNormalizing(p:FlxBasePoint):Float {
		final length = p.length;
		final result = length < FlxPoint.EPSILON_LENGTH ? 0 : dotProductXY(p.x / length, p.y / length);
		p.putWeak();
		return result;
	}

	public function isPerpendicular(p:FlxBasePoint):Bool return Math.abs(dotProduct(p)) < FlxPoint.EPSILON_SQUARED;

	public function crossProductLength(p:FlxBasePoint):Float {
		var cp = crossProductLengthWeak(p);
		p.putWeak();
		return cp;
	}

	function crossProductLengthWeak(p:FlxBasePoint):Float return x * p.y - y * p.x;

	public function isParallel(p:FlxBasePoint):Bool {
		var pp = isParallelWeak(p);
		p.putWeak();
		return pp;
	}

	function isParallelWeak(p:FlxBasePoint):Bool return Math.abs(crossProductLengthWeak(p)) < FlxPoint.EPSILON_SQUARED;

	public function isZero():Bool return Math.abs(x) < FlxPoint.EPSILON && Math.abs(y) < FlxPoint.EPSILON;

	public function zero():FlxBasePoint return set(0, 0);

	public function normalize():FlxBasePoint return isZero() ? this : scale(1 / length);

	public function isNormalized():Bool return Math.abs(lengthSquared - 1) < FlxPoint.EPSILON_SQUARED;

	public function rotateByRadians(rads:Float):FlxBasePoint {
		var s:Float = Math.sin(rads);
		var c:Float = Math.cos(rads);
		return set(x * c - y * s, x * s + y * c);
	}

	public function rotateByDegrees(degs:Float):FlxBasePoint return rotateByRadians(degs * FlxAngle.TO_RAD);

	public function rotateWithTrig(sin:Float, cos:Float):FlxBasePoint return set(x * cos - y * sin, x * sin + y * cos);

	public function setPolarRadians(length:Float, radians:Float):FlxBasePoint
		return set(length * Math.cos(radians), length * Math.sin(radians));

	public function setPolarDegrees(length:Float, degrees:Float):FlxBasePoint return setPolarRadians(length, degrees * FlxAngle.TO_RAD);

	public function rightNormal(?p:FlxBasePoint):FlxBasePoint return p == null ? get(rx, ry) : p.set(rx, ry);

	public function leftNormal(?p:FlxBasePoint):FlxBasePoint return p == null ? get(lx, ly) : p.set(lx, ly);

	public function negate():FlxBasePoint return set(-x, -y);

	public function negateNew(?result:FlxBasePoint):FlxBasePoint return copyTo(result).set(-x, -y);

	public function projectTo(p:FlxBasePoint, ?proj:FlxBasePoint):FlxBasePoint {
		var dp:Float = dotProductWeak(p);
		var lenSq:Float = p.lengthSquared;

		if (proj == null) proj = get();

		proj.set(dp * p.x / lenSq, dp * p.y / lenSq);
		p.putWeak();
		return proj;
	}

	public function projectToNormalized(p:FlxBasePoint, ?proj:FlxBasePoint):FlxBasePoint {
		proj = projectToNormalizedWeak(p, proj);
		p.putWeak();
		return proj;
	}

	inline function projectToNormalizedWeak(p:FlxBasePoint, ?proj:FlxBasePoint):FlxBasePoint {
		var dp:Float = dotProductXY(p.x, p.y);
		if (proj == null) proj = get();
		return proj.set(dp * p.x, dp * p.y);
	}

	public inline function perpProduct(p:FlxBasePoint):Float {
		var pp:Float = perpProductXY(p.x, p.y);
		p.putWeak();
		return pp;
	}

	public function perpProductWeak(p:FlxBasePoint):Float return perpProductXY(p.x, p.y);

	public function perpProductXY(x:Float, y:Float):Float return lx * x + ly * y;

	public function ratio(a:FlxBasePoint, b:FlxBasePoint, p:FlxBasePoint):Float {
		var r = ratioWeak(a, b, p);
		a.putWeak();
		b.putWeak();
		p.putWeak();
		return r;
	}

	public function ratioWeak(a:FlxBasePoint, b:FlxBasePoint, p:FlxBasePoint):Float {
		if (isParallelWeak(p)) return Math.NaN;
		if (lengthSquared < FlxPoint.EPSILON_SQUARED || p.lengthSquared < FlxPoint.EPSILON_SQUARED) return Math.NaN;

		_point1 = b.clone(_point1);
		_point1.subtract(a.x, a.y);

		return _point1.perpProductWeak(p) / perpProductWeak(p);
	}

	public function findIntersection(a:FlxBasePoint, b:FlxBasePoint, p:FlxBasePoint, ?intersection:FlxBasePoint):FlxBasePoint {
		if (intersection == null) intersection = get();

		final t = ratioWeak(a, b, p);
		if (Math.isNaN(t)) intersection.set(Math.NaN, Math.NaN);
		else intersection.set(a.x + t * x, a.y + t * y);

		a.putWeak();
		b.putWeak();
		p.putWeak();
		return intersection;
	}

	public function findIntersectionInBounds(a:FlxBasePoint, b:FlxBasePoint, p:FlxBasePoint, ?intersection:FlxBasePoint):FlxBasePoint {
		if (intersection == null) intersection = get();

		final t1 = ratioWeak(a, b, p);
		final t2 = p.ratioWeak(b, a, this);
		if (!Math.isNaN(t1) && !Math.isNaN(t2) && t1 > 0 && t1 <= 1 && t2 > 0 && t2 <= 1)
			intersection.set(a.x + t1 * x, a.y + t1 * y);
		else
			intersection.set(Math.NaN, Math.NaN);

		a.putWeak();
		b.putWeak();
		p.putWeak();
		return intersection;
	}

	public function truncate(max:Float):FlxBasePoint {
		length = Math.min(max, length);
		return this;
	}

	public function radiansBetween(p:FlxBasePoint):Float {
		var rads = Math.acos(dotProductWeak(p) / (length * p.length));
		p.putWeak();
		return rads;
	}

	public function degreesBetween(p:FlxBasePoint):Float return radiansBetween(p) * FlxAngle.TO_DEG;

	public function sign(a:FlxBasePoint, b:FlxBasePoint):Int {
		var signFl:Float = (a.x - x) * (b.y - y) - (a.y - y) * (b.x - x);
		a.putWeak();
		b.putWeak();
		if (signFl == 0) return 0;
		return Math.round(signFl / Math.abs(signFl));
	}

	public function bounce(normal:FlxBasePoint, bounceCoeff:Float = 1):FlxBasePoint {
		var d:Float = (1 + bounceCoeff) * dotProductWeak(normal);
		set(x - d * normal.x, y - d * normal.y);
		normal.putWeak();
		return this;
	}

	public function bounceWithFriction(normal:FlxBasePoint, bounceCoeff:Float = 1, friction:Float = 0):FlxBasePoint {
		final dp = dotProductWeak(normal);
		final bounceX = -normal.x * dp;
		final bounceY = -normal.y * dp;
		final pp = perpProductWeak(normal);
		final frictionX = normal.rx * pp;
		final frictionY = normal.ry * pp;

		normal.putWeak();

		return set(bounceX * bounceCoeff + frictionX * friction, bounceY * bounceCoeff + frictionY * friction);
	}

	public function isValid():Bool return !Math.isNaN(x) && !Math.isNaN(y) && Math.isFinite(x) && Math.isFinite(y);

	public function clone(?p:FlxBasePoint):FlxBasePoint return copyTo(p);
}

/**
 * A point that, once set, cannot be changed. Useful for objects
 * that want to expose a readonly `x` and `y` value
 * @since 6.0.0
 */
@:forward
@:forward.new
abstract FlxReadOnlyPoint(FlxPoint) from FlxPoint
{
	public var x(get, never):Float;
	public var y(get, never):Float;
	
	/** Length of the point */
	public var length(get, never):Float;
	
	/** The angle formed by the point with the horizontal axis (in degrees) */
	public var degrees(get, never):Float;

	/** The angle formed by the point with the horizontal axis (in radians) */
	public var radians(get, never):Float;
	
	inline function get_x():Float return this.x;
	inline function get_y():Float return this.y;
	inline function get_length():Float return this.length;
	inline function get_radians():Float return this.radians;
	inline function get_degrees():Float return this.degrees;
	
	// hide underlying mutators
	overload inline extern function set(x, y):FlxReadOnlyPoint return this.set(x, y);
	overload inline extern function set(x):FlxReadOnlyPoint return this.set(x);
	overload inline extern function set():FlxReadOnlyPoint return this.set();
	inline function add(x = 0, y = 0):FlxReadOnlyPoint return this.add(x, y);
	inline function addPoint(point):FlxReadOnlyPoint return this.add(point);
	inline function subtract(x = 0, y = 0):FlxReadOnlyPoint return this.subtract(x, y);
	inline function subtractPoint(point):FlxReadOnlyPoint return this.subtract(point);
	inline function scale(x = 0, y = 0):FlxReadOnlyPoint return this.scale(x, y);
	inline function scalePoint(point):FlxReadOnlyPoint return this.scale(point);
	inline function copyFrom(point):FlxReadOnlyPoint return this.copyFrom(point);
	inline function copyFromFlash(point):FlxReadOnlyPoint return this.copyFrom(point);
	inline function floor():FlxReadOnlyPoint return this.floor();
	inline function ceil():FlxReadOnlyPoint return this.ceil();
	inline function round():FlxReadOnlyPoint return this.round();
	inline function rotate(pivot, degrees):FlxReadOnlyPoint return this.pivotDegrees(pivot, degrees);
	inline function pivotRadians(pivot, radians):FlxReadOnlyPoint return this.pivotRadians(pivot, radians);
	inline function pivotDegrees(pivot, degrees):FlxReadOnlyPoint return this.pivotDegrees(pivot, degrees);
	inline function transform(matrix):FlxReadOnlyPoint return this.transform(matrix);
	inline function zero():FlxReadOnlyPoint return this.zero();
	inline function normalize():FlxReadOnlyPoint return this.normalize();
	inline function rotateByRadians(rads):FlxReadOnlyPoint return this.rotateByRadians(rads);
	inline function rotateByDegrees(degs):FlxReadOnlyPoint return this.rotateByDegrees(degs);
	inline function rotateWithTrig(sin, cos):FlxReadOnlyPoint return this.rotateWithTrig(sin, cos);
	inline function setPolarRadians(length, radians):FlxReadOnlyPoint return this.setPolarRadians(length, radians);
	inline function setPolarDegrees(length, degrees):FlxReadOnlyPoint return this.setPolarDegrees(length, degrees);
	inline function negate():FlxReadOnlyPoint return this.negate();
	inline function truncate(max):FlxReadOnlyPoint return this.truncate(max);
	inline function bounce(normal, coeff = 1.0):FlxReadOnlyPoint return this.bounce(normal, coeff);
	inline function bounceWithFriction(normal, coeff = 1.0, friction = 0.0):FlxReadOnlyPoint return this.bounce(normal, coeff);
}

/**
 * A FlxPoint that calls a function when set_x(), set_y() or set() is called. Used in FlxSpriteGroup.
 * IMPORTANT: Calling set(x, y); is MUCH FASTER than setting x and y separately. Needs to be destroyed unlike simple FlxPoints!
 */
class FlxCallbackPoint extends FlxBasePoint
{
	var _setXCallback:FlxPoint->Void;
	var _setYCallback:Null<FlxPoint->Void>;
	var _setXYCallback:Null<FlxPoint->Void>;

	/**
	 * If you only specify one callback function, then the remaining two will use the same.
	 *
	 * @param	setXCallback	Callback for set_x()
	 * @param	setYCallback	Callback for set_y()
	 * @param	setXYCallback	Callback for set()
	 */
	public function new(setXCallback:FlxPoint->Void, ?setYCallback:FlxPoint->Void, ?setXYCallback:FlxPoint->Void)
	{
		super();
		
		// TODO: operator overloading?
		if (setXCallback != null && setYCallback == null && setXYCallback == null)
		{
			_setXYCallback = setXCallback;
		}
		else
		{
			_setXCallback = setXCallback;
			_setYCallback = setYCallback;
			_setXYCallback = setXYCallback;
		}
	}

	override function set(x:Float = 0, y:Float = 0)
	{
		@:bypassAccessor this.x = x;
		@:bypassAccessor this.y = y;
		
		if (_setXCallback != null)
			_setXCallback(this);
		
		if (_setYCallback != null)
			_setYCallback(this);
		
		if (_setXYCallback != null)
			_setXYCallback(this);
		
		return this;
	}

	override function set_x(value:Float):Float
	{
		super.set_x(value);
		
		if (_setXCallback != null)
			_setXCallback(this);
		
		if (_setXYCallback != null)
			_setXYCallback(this);
		
		return value;
	}

	override function set_y(value:Float):Float
	{
		super.set_y(value);
		
		if (_setYCallback != null)
			_setYCallback(this);
		
		if (_setXYCallback != null)
			_setXYCallback(this);
		
		return value;
	}

	override public function destroy():Void
	{
		super.destroy();
		_setXCallback = null;
		_setYCallback = null;
		_setXYCallback = null;
	}

	override public function put():Void {} // don't pool FlxCallbackPoints
}