package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.system.frontEnds.SoundFrontEnd;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
#if flash
import openfl.text.AntiAliasType;
import openfl.text.GridFitType;
#end

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 */
class FlxSoundTray extends Sprite
{
	/**
		The sound that'll play when you change volume.
	**/
	public static var volumeChangeSFX:String = "flixel/sounds/beep";

	/**
		The sound that'll play when you try to increase volume and it's already on the max.
	**/
	public static var volumeMaxChangeSFX:String = null;

	/**
		The sound that'll play when you increase volume.
	**/
	public static var volumeUpChangeSFX:String = null;

	/**
		The sound that'll play when you decrease volume.
	**/
	public static var volumeDownChangeSFX:String = null;

	/**
		Whether or not changing the volume should make noise.
	**/
	public static var silent:Bool = false;

	/**
	 * "VOLUME" text.
	 */
	public var text:TextField = new TextField();

	/**
	 * The default text format of soundtray object's text.
	 */
	var _dtf:TextFormat;

	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	var _timer:Float;

	/**
	 * Helps display the volume bars on the sound tray.
	 */
	var _bars:Array<Bitmap>;

	var _bx:Int = 10;

	var _by:Int = 14;

	/**
	 * The amount of the volume bars on the sound tray.
	 *
	 * Automatically calls `regenerateBars` each time the value changes.
	 */
	public var barsAmount(default, set):Int = 10;

	@:dox(hide) public function set_barsAmount(value:Int):Int
	{
		barsAmount = value;
		regenerateBars();
		return value;
	}

	/**
	 * The sound tray background Bitmap.
	 */
	public var background:Bitmap;

	/**
	 * How wide the sound tray background is.
	 */
	@:isVar var _width(get, set):Int = 80;

	@:dox(hide) public function get__width():Int
	{
		if (background != null)
			_width = Math.round(background.width); // Must round this to an Int to keep backwards compatibility  - Nex
		return _width;
	}

	@:dox(hide) public function set__width(value:Int):Int
	{
		if (background != null)
			background.width = value;
		return _width = value;
	}

	/**
	 * How long the sound tray background is.
	 */
	@:isVar var _height(get, set):Int = 30;

	@:dox(hide) public function get__height():Int
	{
		if (background != null)
			_height = Math.round(background.height);
		return _height;
	}

	@:dox(hide) public function set__height(value:Int):Int
	{
		if (background != null)
			background.height = value;
		return _height = value;
	}

	var _defaultScale:Float = 2.0;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep
	public function new()
	{
		super();

		background = new Bitmap(new BitmapData(_width, _height, true, 0x7F000000));
		screenCenter();
		addChild(background);

		reloadText(false);
		regenerateBars();

		y = -height;
		visible = false;
	}

	/**
	 * This function regenerates the text of soundtray object.
	 */
	public function reloadText(checkIfNull:Bool = true, reloadDefaultTextFormat:Bool = true, displayTxt:String = "VOLUME", y:Float = 16):Void
	{
		if (checkIfNull && text != null)
		{
			removeChild(text);
			@:privateAccess
			text.__cleanup();
		}

		text = new TextField();
		text.width = _width;
		text.height = _height;
		text.multiline = true;
		text.wordWrap = true;
		text.selectable = false;

		#if flash
		text.embedFonts = true;
		text.antiAliasType = AntiAliasType.NORMAL;
		text.gridFitType = GridFitType.PIXEL;
		#end
		if (reloadDefaultTextFormat)
			reloadDtf();
		text.defaultTextFormat = _dtf;
		addChild(text);
		text.text = displayTxt;
		text.y = y;
	}

	/**
	 * This function reloads the default text format of soundtray object's text.
	 */
	public function reloadDtf():Void
	{
		_dtf = new TextFormat(FlxAssets.FONT_DEFAULT, 10, 0xffffff);
		_dtf.align = TextFormatAlign.CENTER;
	}

	public function regenerateBarsArray():Void
	{
		if (_bars == null)
			_bars = new Array();
		else
			for (bar in _bars)
			{
				_bars.remove(bar);
				removeChild(bar);
				bar.bitmapData.dispose();
			}
	}

	/**
	 * This function regenerates the bars of the soundtray object according to `barsAmount`.
	 */
	public function regenerateBars():Void
	{
		var tmp:Bitmap;
		var bx:Int = _bx;
		var by:Int = _by;

		regenerateBarsArray();
		for (i in 0...barsAmount)
		{
			tmp = new Bitmap(new BitmapData(4, i + 1, false, FlxColor.WHITE));
			tmp.x = bx;
			tmp.y = by;
			addChild(tmp);
			_bars.push(tmp);
			bx += 6;
			by--;
		}
	}

	/**
	 * This function updates the soundtray object.
	 */
	public function update(MS:Float):Void
	{
		// Animate sound tray thing
		if (_timer > 0)
		{
			_timer -= MS / 1000;
		}
		else if (y > -height)
		{
			y -= (MS / 1000) * FlxG.height * 2;

			if (y <= -height)
			{
				visible = false;
				active = false;
				saveSoundPreferences();
			}
		}
	}

	public function saveSoundPreferences():Void
	{
		var save = SoundFrontEnd.save;
		save.data.mute = FlxG.sound.muted;
		save.data.volume = FlxG.sound.volume;
		save.flush();
	}

	/**
	 * Makes the little volume tray slide out.
	 */
	public function show(up:Bool = false):Void
	{
		var globalVolume:Int = FlxG.sound.muted ? 0 : Math.round(FlxG.sound.volume * barsAmount);

		_timer = 1;
		y = 0;
		visible = true;
		active = true;

		if (!silent)
		{
			var sound = up ? (globalVolume >= barsAmount
				&& volumeMaxChangeSFX != null ? volumeMaxChangeSFX : volumeUpChangeSFX) : volumeDownChangeSFX;
			if (sound == null)
				sound = volumeChangeSFX;
			FlxG.sound.load(sound).play();
		}

		for (i in 0..._bars.length)
		{
			if (_bars[i] != null)
				_bars[i].alpha = i < globalVolume ? 1 : 0.5;
		}
	}

	public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}
}
#end
