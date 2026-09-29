package flixel.util;

import openfl.geom.Matrix3D;
import flixel.util.FlxColor;
import flixel.math.FlxMath;

/**
 * Helper 4x4 matrix class for advanced color editing.
 * It mostly copies Matrix3D class, but with some miscellaneous additions.
 */
class FlxColorMatrix extends Matrix3D {
	/**
	 * Dummy matrix that stores default color info.
	 * To reset any `colorMatrix`, just do `colorMatrix.identity()`.
	 */
	public static final colorIdentity:FlxColorMatrix = new FlxColorMatrix();

	/**
	 * Short-hand value to get/set the color that replaces the red channel. Alpha channel is ignored.
	 */
	public var red(get, set):FlxColor;
	public function get_red():FlxColor { return FlxColor.fromRGBFloat(rawData[0], rawData[4], rawData[8]); }
	public function set_red(v:FlxColor):FlxColor { 
		rawData[0] = v.redFloat;
		rawData[4] = v.greenFloat;
		rawData[8] = v.blueFloat;
		return v;
	}

	/**
	 * Short-hand value to get/set the color that replaces the green channel. Alpha channel is ignored.
	 */
	public var green(get, set):FlxColor;
	public function get_green():FlxColor { return FlxColor.fromRGBFloat(rawData[1], rawData[5], rawData[9]); }
	public function set_green(v:FlxColor):FlxColor { 
		rawData[1] = v.redFloat;
		rawData[5] = v.greenFloat;
		rawData[9] = v.blueFloat;
		return v;
	}

	/**
	 * Short-hand value to get/set the color that replaces the blue channel. Alpha channel is ignored.
	 */
	public var blue(get, set):FlxColor;
	public function get_blue():FlxColor { return FlxColor.fromRGBFloat(rawData[2], rawData[6], rawData[10]); }
	public function set_blue(v:FlxColor):FlxColor { 
		rawData[2] = v.redFloat;
		rawData[6] = v.greenFloat;
		rawData[10] = v.blueFloat;
		return v;
	}

	/**
	 * Short-hand value to get/set the color offsets.
	 * Different from `ColorTransform.color` due to not being there in the first place.
	 */
	public var offset(get, set):FlxColor;
	public function get_offset():FlxColor { return FlxColor.fromRGBFloat(rawData[3], rawData[7], rawData[11]); }
	public function set_offset(v:FlxColor):FlxColor { 
		rawData[3] = v.redFloat;
		rawData[7] = v.greenFloat;
		rawData[11] = v.blueFloat;
		return v;
	}

	public function setRGB(?r:FlxColor = 0xFF0000, ?g:FlxColor = 0x00FF00, ?b:FlxColor = 0x0000FF, ?o:FlxColor = 0x000000) {
		red = r;
		green = g;
		blue = b;
		offset = o;
	}

	/**
	 * Short-hand hue rotation, in degrees.
	 * Will only override the upper-left 3x3 matrix... whatever that means.
	 */
	public var hue(default, set):Float = 0;
	public function set_hue(v:Float):Float {
		var cosHue = Math.cos(v * Math.PI / 180);
		var sinHue = Math.sin(v * Math.PI / 180);
		rawData[ 0] = 0.213 + cosHue *  0.787 + sinHue * -0.213;
		rawData[ 4] = 0.213 + cosHue * -0.213 + sinHue *  0.143;
		rawData[ 8] = 0.213 + cosHue * -0.213 + sinHue * -0.787;
		rawData[ 1] = 0.715 + cosHue * -0.715 + sinHue * -0.715;
		rawData[ 5] = 0.715 + cosHue *  0.285 + sinHue *  0.140;
		rawData[ 9] = 0.715 + cosHue * -0.715 + sinHue *  0.715;
		rawData[ 2] = 0.072 + cosHue * -0.072 + sinHue *  0.928;
		rawData[ 6] = 0.072 + cosHue * -0.072 + sinHue * -0.283;
		rawData[10] = 0.072 + cosHue *  0.928 + sinHue *  0.072;
		return hue = v;
	}

	/**
	 * Luminance of red, green, blue channels.
	 * Used in `grayscale`.
	 */
	public static final grayscaleValues = [0.213, 0.715, 0.072];

	/**
	 * Desaturates an image by a specific factor.
	 * @param factor The factor in question (0-1)
	 */
	public function grayscale(factor:Float) {
		for (r in 0...4) {
			for (c in 0...4) {
				var i = r + (c * 4);
				if (i >= 3 * 4 || (i + 1) % 4 == 0) continue;
				
				rawData[i] = FlxMath.lerp(rawData[i], grayscaleValues[r], factor);
			}
		}
	}


	/**
	 * Adjustment for hue, saturation, brightness and contrast
	 * of a sprite, based on Adobe Flash. (not fully accurate).
	 * WIll override the current matrix.
	 * 
	 * @param hue Hue (-360 <-> 360)
	 * @param sat Saturation (-100 <-> 100)
	 * @param bri Brightness (-100 <-> 100)
	 * @param con Contrast (-100 <-> 100)
	 */
	public function adjustColor(?hue:Float = 0, ?sat:Float = 0, ?bri:Float = 0, ?con:Float = 0) {
		for (i in 0...3) {
			rawData[(i * 4) + 3] = (bri / 255);
		}

		this.hue = hue;

		// contrast
		var value = con;
		value = (1.0 + (value / 100.0));
		for (r in 0...4) {
			for (c in 0...4) {
				var i = r + (c * 4);
				if (i >= 3 * 4 || (i + 1) % 4 == 0) continue;
				
				rawData[i] *= value;
			}
			if (r < 3) rawData[(r * 4) + 3] += 0.5 * (1 - value);
		}

		// saturation
		var satFactor = sat;
		if (satFactor > 0) satFactor *= 3;
		satFactor = 1 + (satFactor / 100);
		grayscale(1 - satFactor);
	}
}
