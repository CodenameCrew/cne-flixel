package flixel.sound;

import lime.media.AudioSource;
import lime.media.AudioFilter;
import lime.media.AudioFilterType;
import flixel.util.FlxDestroyUtil;

enum abstract FlxSoundFilterType(Int) from Int to Int
{
	var NONE = 0;
	var LOWPASS = 1;
	var HIGHPASS = 2;
	var BANDPASS = 3;

	public static function fromLime(value:AudioFilterType):FlxSoundFilterType
	{
		return switch (cast value : AudioFilterType)
		{
			case AudioFilterType.NONE: FlxSoundFilterType.NONE;
			case AudioFilterType.LOWPASS: FlxSoundFilterType.LOWPASS;
			case AudioFilterType.HIGHPASS: FlxSoundFilterType.HIGHPASS;
			case AudioFilterType.BANDPASS: FlxSoundFilterType.BANDPASS;
		}
	}

	public function toLime():AudioFilterType
	{
		return switch (cast this : FlxSoundFilterType)
		{
			case FlxSoundFilterType.NONE: AudioFilterType.NONE;
			case FlxSoundFilterType.LOWPASS: AudioFilterType.LOWPASS;
			case FlxSoundFilterType.HIGHPASS: AudioFilterType.HIGHPASS;
			case FlxSoundFilterType.BANDPASS: AudioFilterType.BANDPASS;
		}
	}
}

/**
 * An object that can be used to apply filters and effects to a `FlxSound` object.
 * @since FunkinCrew's Flixel
 */
class FlxSoundFilter implements IFlxDestroyable
{
	/**
	 * The type of this filter.
	 * Default variable is `NONE`
	 * 
	 * `NONE` will make the filter to be deactivated.
	 * 
	 * `LOWPASS` will allow for the volume of high frequency sounds to be reduced.
	 * 
	 * `HIGHPASS` will allow for the volume of low frequency sounds to be reduced.
	 * 
	 * `BANDPASS` will allow for the volume of both low and high frequency sounds to be reduced individually.
	 */
	public var type(default, set):FlxSoundFilterType;

	/**
	 * A variable representing a frequency in the current filtering algorithm measured, in hz.
	 * Ranging from 0 to 24000, Default variable is `1000`.
	 */
	public var frequency(get, set):Float;

	/**
	 * Determines if the filter should be automatically destroyed when it's unused.
	 */
	public var autoDestroy:Bool = true;

	/**
	 * Usage counter for this `FlxSoundFilter` object.
	 */
	public var useCount(default, null):Int = 0;

	/**
	 * The internal filter Lime `AudioFilter` variable to use for sound filter and effects.
	 */
	public final filter:AudioFilter;

	/**
	 * Constructor for `FlxSoundFilter`.
	 */
	public function new()
	{
		filter = new AudioFilter();
		type = FlxSoundFilterType.fromLime(filter.type);
	}

	/**
	 * Releases resources that used by this `FlxSoundFilter` from memory.
	 */
	public function destroy():Void
	{
		filter.dispose();
	}

	public function incrementUseCount()
	{
		useCount++;
	}
	
	public function decrementUseCount()
	{
		useCount--;
		
		if (useCount <= 0 && autoDestroy) destroy();
	}

	inline function set_type(value:FlxSoundFilterType):FlxSoundFilterType
	{
		if (filter != null) filter.type = value.toLime();
		return type = value;
	}

	inline function get_frequency():Float
	{
		return filter?.frequency ?? 0;
	}

	inline function set_frequency(value:Float):Float
	{
		if (filter != null) filter.frequency = value;
		return value;
	}
}