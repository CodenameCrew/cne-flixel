package flixel.sound;

import lime.media.AudioBuffer;
import lime.media.AudioEffect;
import lime.media.AudioSource;

import openfl.events.Event;
import openfl.events.IEventDispatcher;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import flixel.util.FlxStringUtil;

/**
 * This is the universal flixel sound object, used for streaming, music, and sound effects.
 */
@:access(lime.media.AudioBuffer)
@:access(lime.media.AudioSource)
@:access(openfl.media.Sound)
@:access(flixel.FlxGame)
@:allow(flixel.system.frontEnds.SoundFrontEnd)
class FlxSound extends FlxBasic
{
	#if FLX_PITCH
	/**
	 * The default value for the `timeScaledPitch` variable at creation if none is specified in the constructor.
	 */
	public static var defaultTimeScaledPitch:Bool = false;
	#end

	/**
	 * Plays all of FlxSound instance at the same time.
	 * 
	 * @param	sounds			Array list of FlxSounds to play or resume.
	 * @param	forceRestart	Whether to start the sound over or not.
	 *							Default value is false, meaning if the sound is already playing or was
	 *							paused when you call play(), it will continue playing from its current
	 *							position, NOT start again from the beginning.
	 */
	public static function playSounds(sounds:Array<FlxSound>):Void
	{
		var sources:Array<AudioSource> = [];

		for (sound in sounds)
		{
			if (sound == null || !sound.exists) continue;

			if (sound._pausedByHandler) sound.resume();
			else
			{
				sources.push(sound.source);

				sound._updateVolume();
				#if FLX_PITCH
				sound._updatePitch();
				#end
				sound._updatePan();
				sound._updateLoop();

				sound._paused = false;
				sound._completed = false;
				sound.active = false;
			}
		}

		AudioSource.playSources(sources);
	}

	/**
	 * Pauses all of FlxSound instance at the same time.
	 * 
	 * @param	sounds	Array list of FlxSounds to pause.
	 */
	public static function pauseSounds(sounds:Array<FlxSound>):Void
	{
		var sources:Array<AudioSource> = [];

		for (sound in sounds)
		{
			if (sound == null || !sound.exists || !sound.playing) continue;

			sources.push(sound.source);

			sound.get_time();
			sound._timeTicks = null;
			sound._pausedByHandler = false;
			sound._pausedPlay = false;
			sound._paused = true;
			sound.active = false;
		}

		AudioSource.pauseSources(sources);
	}

	/**
	 * Stops all of FlxSound instance at the same time.
	 * 
	 * @param	sounds	Array list of FlxSounds to pause.
	 */
	public static function stopSounds(sounds:Array<FlxSound>):Void
	{
		var sources:Array<AudioSource> = [];

		for (sound in sounds)
		{
			if (sound == null || !sound.exists || !sound.playing) continue;

			sound._timeTicks = null;
			sound._pausedByHandler = false;
			sound._pausedPlay = false;
			sound._paused = true;
			sound.active = false;

			if (sound.autoDestroy) sound.kill();
			else sources.push(sound.source);
		}

		AudioSource.pauseSources(sources);
	}

	//#if flash
	/**
	 * The ID3 song name. Defaults to null. Currently only works for streamed sounds.
	 */
	public var name(default, null):String;

	/**
	 * The ID3 artist name. Defaults to null. Currently only works for streamed sounds.
	 */
	public var artist(default, null):String;
	//#end

	/**
	 * Whether or not this sound should be automatically destroyed when you switch states.
	 */
	public var persist:Bool;

	/**
	 * Whether to call `destroy()` when the sound has finished playing.
	 * since FunkinCrew's Flixel, internally it calls `kill()` to be reused again by FlxG.sound.load.
	 */
	public var autoDestroy:Bool;

	/**
	 * Whether or not this audio should have proximity stuff.
	 * @since FunkinCrew's Flixel
	 */
	public var proximityEnabled(default, set):Bool;

	/**
	 * Whether the proximity alters the pan or not.
	 * Default is true.
	 * @since FunkinCrew's Flixel
	 */
	public var proximityPan(default, set):Bool;

	/**
	 * The x position of this sound in world coordinates.
	 * Only really matters if you are doing proximity/panning stuff.
	 */
	public var x:Float;

	/**
	 * The y position of this sound in world coordinates.
	 * Only really matters if you are doing proximity/panning stuff.
	 */
	public var y:Float;

	/**
	 * Controls how much this object is affected by camera scrolling. `0` = no movement (e.g. a static sound),
	 * This is only useful if used with proximity (Initialized once proximity is used).
	 * Default is 0, 0.
	 * @since FunkinCrew's Flixel
	 */
	public var scrollFactor(default, null):FlxPoint;

	/**
	 * The sound's "target" (for proximity and panning).
	 */
	public var target:Null<FlxObject>;

	/**
	 * The maximum effective radius of this sound (for proximity and panning).
	 * Default is 1024.
	 * @since FunkinCrew's Flixel
	 */
	public var radius:Float;

	/**
	 * The sound group this sound belongs to, can only be in one group.
	 * NOTE: This setter is deprecated, use `group.add(sound)` or `group.remove(sound)`.
	 */
	public var group(default, set):FlxSoundGroup;

	/**
	 * Whether or not the sound is currently playing.
	 */
	public var playing(get, never):Bool;

	/**
	 * Whether or not the sound is currently paused.
	 * @since FunkinCrew's Flixel
	 */
	public var paused(get, never):Bool;

	/**
	 * Whether or not the sound has been completed.
	 * @since FunkinCrew's Flixel
	 */
	public var completed(get, never):Bool;

	/**
	 * Set volume to a value between 0 and 1* to change how this sound is.
	 */
	public var volume(get, set):Float;

	/**
	 * Whether to make this sound muted or not.
	 * @since FunkinCrew's Flixel
	 */
	public var muted(get, set):Bool;

	#if FLX_PITCH
	/**
	 * Set pitch, which also alters the playback speed. Default is 1.
	 * @since 5.0.0
	 */
	public var pitch(get, set):Float;

	/**
	 * Alters the pitch of the sound depends on the current FlxG.timeScale.
	 * @since FunkinCrew's Flixel
	 */
	public var timeScaledPitch(get, set):Bool;
	#end

	/**
	 * Pan amount. -1 = full left, 1 = full right. Proximity based panning overrides this.
	 */
	public var pan(get, set):Float;

	/**
	 * The duration/length of the sound in milliseconds.
	 * @since 4.2.0
	 */
	public var length(get, never):Float;

	/**
	 * Whether or not this sound should loop.
	 */
	public var looped(get, set):Bool;

	/**
	 * The number of times this sound was restarted, via the `looped` flag.
	 * Automatically incremented on loops, and reset to 0 when restarted.
	 * @since 6.2.0
	 */
	public var loopCount(default, null):Int;

	/**
	 * The number of times this sound should loop, where `-1` loops forever, and `1` is
	 * repeated once. This field is ignored if `looped` is `false`.
	 * Default is '-1'.
	 * @since 6.2.0
	 */
	public var loopUntil(default, set):Int;

	/**
	 * The time (in milliseconds) from where to restart the sound when it loops back
	 * @since 4.1.0
	 */
	public var loopTime(get, set):Float;

	/**
	 * At which point to stop playing the sound, in milliseconds.
	 * If not set / `null`, the sound completes normally.
	 * @since 4.2.0
	 */
	public var endTime(get, set):Null<Float>;

	/**
	 * The position in runtime of the sound playback in milliseconds.
	 * If set while paused, changes only come into effect after a `resume()` call.
	 */
	public var time(get, set):Float;

	/**
	 * The offset for this sound.
	 * Useful for just generally offsetting this sound without affecting time.
	 * @since FunkinCrew's Flixel
	 */
	public var offset:Float;

	/**
	 * The current latency of this sound in milliseconds.
	 * @since FunkinCrew's Flixel
	 */
	public var latency(get, never):Float;

	/**
	 * The peak of this current sound playback.
	 * NOTE: It is in linear signal, not in volume.
	 */
	public var amplitude(get, never):Float;

	/**
	 * The peak of this current sound playback, seperated to channels.
	 * NOTE: It is in linear signal, not in volume.
	 * @since FunkinCrew's Flixel
	 */
	public var amplitudes(get, never):Array<Float>;

	/**
	 * Just the amplitude of the left stereo channel.
	 * NOTE: It is in linear signal, not in volume.
	 */
	public var amplitudeLeft(get, never):Float;

	/**
	 * Just the amplitude of the right stereo channel.
	 * NOTE: It is in linear signal, not in volume.
	 */
	public var amplitudeRight(get, never):Float;

	/**
	 * Whether or not this sound is loaded yet.
	 * @since FunkinCrew's Flixel
	 */
	public var loaded(default, null):Bool;

	/**
	 * The current `FlxSoundData` to load in this sound.
	 * @since FunkinCrew's Flixel
	 */
	public var data(default, null):FlxSoundData;

	/**
	 * The tween used to fade this sound's volume in and out (set via `fadeIn()` and `fadeOut()`)
	 * @since 4.1.0
	 */
	public var fadeTween:FlxTween;

	/**
	 * The internal lime 'AudioSource' to playback sounds.
	 * @since FunkinCrew's Flixel
	 */
	public final source:AudioSource;

	/**
	 * Signal that is dispatched on sound complete.
	 * @since FunkinCrew's Flixel
	 */
	public final onFinish:FlxSignal = new FlxSignal();

	/**
	 * Signal that is dispatched on sound destroy then clears all of the dispatchers.
	 * @since FunkinCrew's Flixel
	 */
	public final onDestroy:FlxSignal = new FlxSignal();

	/**
	 * Tracker for sound complete callback. If assigned, will be called
	 * each time whenever sound reaches its end.
	 */
	//@:deprecated("`FlxSound.onComplete` is deprecated! Use `FlxSound.onFinish` instead.")
	public var onComplete:Void->Void;

	var _paused:Bool;
	var _completed:Bool;
	var _volume:Float;
	var _volumeAdjust:Float;
	var _muted:Bool;
	#if FLX_PITCH
	var _timeScaledPitch:Bool;
	var _pitch:Float;
	//var _pitchAdjust:Float;
	#end
	var _pan:Float;
	var _panAdjust:Float;
	var _looped:Bool;
	var _loopTime:Float;
	var _endTime:Null<Float>;
	var _lastTime:Float;
	var _timeTicks:Null<Float>;
	var _timeInterpolation:Float;
	var _pausedByHandler:Bool;
	var _pausedPlay:Bool;
	var _amplitude:Float;
	var _amplitudes:Array<Float>;
	var _amplitudeUpdated:Bool;
	var _point:FlxPoint;
	var _point2:FlxPoint;

	/**
	 * The FlxSound constructor gets all the variables initialized, but NOT ready to play a sound yet.
	 */
	public function new()
	{
		super();

		source = new AudioSource();
		source.onComplete.add(stopped);

		_amplitudes = [0, 0];

		reset(true);
	}

	/**
	 * A function for clearing all the variables used by sounds.
	 * @param	force	Should it reset everything instead of just only source properties.
	 */
	public function reset(force = false):Void
	{
		stop();

		autoDestroy = false;
		x = y = 0;

		if (force)
		{
			clearEffects();

			persist = false;
			loopUntil = -1;
			proximityEnabled = false;
			proximityPan = true;
			scrollFactor?.set(0, 0);
			target = null;
			radius = 1024;

			looped = false;
			loopTime = 0;
			endTime = null;

			#if FLX_PITCH
			_timeScaledPitch = defaultTimeScaledPitch;
			#end
		}

		offset = 0;
		_paused = true;
		_lastTime = 0;
		_timeTicks = null;
		_volume = 1;
		_volumeAdjust = 1;
		_muted = false;
		#if FLX_PITCH
		_pitch = 1;
		//_pitchAdjust = 1;
		#end
		_pan = 0;
		_panAdjust = 0;

		_updateVolume();
		#if FLX_PITCH
		_updatePitch();
		#end
		_updatePan();
		_updateLoop();
	}

	/**
	 * Destroy this FlxSound from memory.
	 */
	override function destroy():Void
	{
		kill();
		source.dispose();

		_point = FlxDestroyUtil.put(_point);
		_point2 = FlxDestroyUtil.put(_point2);
	}

	/**
	 * Handles fade out, fade in, panning, proximity, and amplitude operations each frame.
	 */
	override function update(elapsed:Float):Void
	{
		if (!playing) return;

		_amplitudeUpdated = false;

		if (proximityEnabled)
		{
			_point = getPosition(_point);
			_point2 = target != null ? target.getPosition(_point2) : FlxPoint.get();

			final camera = camera;
			if (camera != null)
			{
				_point2.subtract(camera.scroll.x * target.scrollFactor.x, camera.scroll.y * target.scrollFactor.y);
				if (scrollFactor != null) _point.subtract(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
			}

			if (_volumeAdjust != (_volumeAdjust = 1 - FlxMath.bound(_point2.distanceTo(_point) / radius, 0, 1))) _updateVolume();
			if (proximityPan && _panAdjust != (_panAdjust = (_point.x - _point2.x) / radius)) _updatePan();
		}
	}

	/**
	 * Resets this sound instance when reviving.
	 */
	override function revive():Void
	{
		reset(true);
	}

	/**
	 * Kill this sound instance, Internally autoDestroy uses kill() instead of destroy().
	 * An alternative method to destroy, but only freeing the unused resources to be reused in later FlxG.sound pool.
	 * 
	 * @since	FunkinCrew's Flixel
	 */
	override function kill():Void
	{
		onDestroy.dispatch();

		unload();

		onDestroy.removeAll();
		onFinish.removeAll();
		onComplete = null;

		if (fadeTween != null)
		{
			fadeTween.cancel();
			fadeTween = null;
		}

		super.destroy();
	}

	/**
	 * Unloads an asset from the sound playback, good for deattaching data.
	 * 
	 * @return	This	FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function unload():FlxSound
	{
		loaded = false;

		source.unload();
		source.buffer = null;
		if (data != null)
		{
			data.decrementUseCount();
			data = null;
		}

		alive = false;
		exists = false;

		loopTime = 0;
		endTime = null;

		return this;
	}

	/**
	 * Loads a sound from the provided sound asset.
	 * The asset can be an OpenFL Sound instance, Lime AudioBuffer instance, embedded sound, file path or byte array.
	 * 
	 * **Note:** If the `FLX_DEFAULT_SOUND_EXT` flag is enabled, you may omit the file extension
	 * 
	 * @param	asset			The sound asset to load.
	 * @param	looped			Optional. Whether or not this sound should loop endlessly.
	 * @param	loopTime		Optional. At which point to start from when audio is looped.
	 * @param	endTime			Optional. When does it ends to loop the audio.
	 * @param	autoDestroy		Whether or not this FlxSound instance should be destroyed when
	 *							the sound finishes playing.
	 * @param	onComplete		Called when the sound finishes playing.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 * 
	 * @since 6.2.0
	 */
	//public function load
	// funkin.audio.FunkinSound already defined load as a static function.
	public function loadEmbedded(asset:FlxSoundAsset, ?looped:Bool, ?loopTime:Float, ?endTime:Float, autoDestroy = false, ?onComplete:Void->Void):FlxSound
	{
		return init(asset == null ? null : FlxSoundData.fromAsset(asset), looped, loopTime, endTime, autoDestroy, onComplete);
	}

	#if FLX_STREAM_SOUND
	/**
	 * Streams a sound from the given file path. Unlike the `load` method, this will load and
	 * unload chunks of data as the sound plays, keeping memory usage low. This is recommended for
	 * longer sounds, like music tracks. For shorter sounds like sound effects, it is better to
	 * use the `load` method, which loads the entire sound into memory before playing it.
	 * 
	 * Due to a backend limitation, audio streaming is currently only available on native targets 
	 * and OGG/Vorbis audio files.
	 * ...Not anymore :) with FunkinCrew's Lime.
	 * 
	 * This does not load sounds from web locations. Use `loadFromURL()` for that, instead.
	 * 
	 * **Note:** If the `FLX_DEFAULT_SOUND_EXT` flag is enabled, you may omit the file extension
	 * 
	 * @param   path         The ID or asset path to the sound asset.
	 * @param   looped       Whether or not this sound should loop endlessly.
	 * @param   autoDestroy  Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 * @param   onComplete   Called when the sound finishes playing.
	 * @return  This FlxSound instance (nice for chaining stuff together, if you're into that).
	 * 
	 * @since 6.2.0
	 */
	public function loadStreamed(path:String, ?looped:Bool, ?loopTime:Float, ?endTime:Float, autoDestroy = false, ?onComplete:Void->Void):FlxSound
	{
		return init(FlxSoundData.fromAssetKey(path, true), looped, loopTime, endTime, autoDestroy, onComplete);
	}
	#end

	/**
	 * Loads a sound from the provided URL.
	 * 
	 * @param	url				A string representing the URL of the sound you want to play.
	 * @param	looped			Optional. Whether or not this sound should loop endlessly.
	 * @param	loopTime		Optional. At which point to start from when audio is looped.
	 * @param	endTime			Optional. When does it ends to loop the audio.
	 * @param	autoDestroy		Whether or not this FlxSound instance should be destroyed when
	 *							the sound finishes playing.
	 * @param	onComplete		Called when the sound finishes playing.
	 * @param	onLoad			Called when the sound finishes loading.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 * 
	 * @since 6.2.0
	 */
	public function loadFromURL(url:String, ?looped:Bool, ?loopTime:Float, ?endTime:Float, autoDestroy:Bool = false,
		?onComplete:Void->Void, ?onLoad:Void->Void):FlxSound
	{
		var sound = new Sound();
		#if flash
		var gotID3:Event->Void = null;
		gotID3 = function(e:Event) {
			name = sound.id3.songName;
			artist = sound.id3.artist;
			sound.removeEventListener(Event.ID3, gotID3);
		}
		sound.addEventListener(Event.ID3, gotID3);
		#end

		var loadCallback:Event->Void = null;
		loadCallback = function(e:Event)
		{
			(e.target : IEventDispatcher).removeEventListener(e.type, loadCallback);
			// Check if the sound was destroyed before calling. Weak ref doesn't guarantee GC.
			if (sound == e.target)
			{
				init(FlxSoundData.fromSound(sound, url), null, null, null, this.autoDestroy, null);
				if (onLoad != null) onLoad();
			}
		}
		// Use a weak reference so this can be garbage collected if destroyed before loading.
		sound.addEventListener(Event.COMPLETE, loadCallback, false, 0, true);
		sound.load(new URLRequest(url));

		return init(null, looped, loopTime, endTime, autoDestroy, onComplete);
	}

	/**
	 * One of the main setup functions for sounds, this function loads a sound from an embedded MP3.
	 * 
	 * **Note:** If the `FLX_DEFAULT_SOUND_EXT` flag is enabled, you may omit the file extension
	 * 
	 * @param	EmbeddedSound	An embedded Class object representing an MP3 file.
	 * @param	Looped			Whether or not this sound should loop endlessly.
	 * @param	AutoDestroy		Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 *							Default value is false, but `FlxG.sound.play()` and `FlxG.sound.loadFromURL()` will set it to true by default.
	 * @param	OnComplete		Called when the sound finished playing
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	//@:deprecated("loadEmbedded() is deprecated, use load() instead.")
	//public function loadEmbedded(EmbeddedSound:FlxSoundAsset, Looped:Bool = false, AutoDestroy:Bool = false, ?OnComplete:Void->Void):FlxSound
	//{
	//	return load(EmbeddedSound, Looped, AutoDestroy, OnComplete);
	//}

	/**
	 * One of the main setup functions for sounds, this function loads a sound from a URL.
	 * 
	 * @param	SoundURL		A string representing the URL of the MP3 file you want to play.
	 * @param	Looped			Whether or not this sound should loop endlessly.
	 * @param	AutoDestroy		Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 *							Default value is false, but `FlxG.sound.play()` and `FlxG.sound.loadFromURL()` will set it to true by default.
	 * @param	OnComplete		Called when the sound finished playing
	 * @param	OnLoad			Called when the sound finished loading.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	@:deprecated("loadStream() is deprecated, use loadFromURL() instead.")
	public function loadStream(SoundURL:String, Looped:Bool = false, AutoDestroy:Bool = false, ?OnComplete:Void->Void, ?OnLoad:Void->Void):FlxSound
	{
		return loadFromURL(SoundURL, Looped, AutoDestroy, OnComplete, OnLoad);
	}

	/**
	 * One of the main setup functions for sounds, this function loads a sound from a ByteArray.
	 * 
	 * @param	Bytes			A ByteArray object.
	 * @param	Looped			Whether or not this sound should loop endlessly.
	 * @param	AutoDestroy		Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 *							Default value is false, but `FlxG.sound.play()` and `FlxG.sound.loadFromURL()` will set it to true by default.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	@:deprecated("loadByteArray() is deprecated, use load() instead.")
	public function loadByteArray(Bytes:ByteArray, Looped:Bool = false, AutoDestroy:Bool = false, ?OnComplete:Void->Void):FlxSound
	{
		return loadEmbedded(Bytes, Looped, AutoDestroy, OnComplete);
	}

	function init(data:FlxSoundData, ?looped:Bool, ?loopTime:Float, ?endTime:Float, autoDestroy = false, ?onComplete:Void->Void):FlxSound
	{
		exists = true;
		alive = true;

		stop();

		this.autoDestroy = autoDestroy;
		this.onComplete = onComplete;

		if (this.data != data)
		{
			if (data != null && !data.isDestroyed)
			{
				this.data = data;
				data.incrementUseCount();

				source.buffer = data.buffer;
				source.load();

				loaded = true;
			}
			else
			{
				unload();
			}
		}

		if (looped != null) this.looped = looped;
		if (loopTime != null) this.loopTime = loopTime;
		if (endTime != null) this.endTime = endTime;

		return this;
	}

	/**
	 * Helper function to set the coordinates of this object.
	 * Audio positioning is used in conjunction with proximity/panning.
	 * 
	 * @param	x	The new X position
	 * @param	y	The new Y position
	 *
	 * @since	FunkinCrew's Flixel
	 */
	public function setPosition(x = 0.0, y = 0.0)
	{
		this.x = x;
		this.y = y;
	}

	/**
	 * Returns the world position of this object.
	 * 
	 * @param	result  Optional arg for the returning point.
	 * @return	The world position of this object.
	 *
	 * @since	FunkinCrew's Flixel
	 */
	public function getPosition(?result:FlxPoint):FlxPoint {
		if (result == null)
			result = FlxPoint.get();

		return result.set(x, y);
	}

	/**
	 * Call this function if you want this sound's volume to change
	 * based on distance from a particular FlxObject.
	 *
	 * @param	x				The X position of the sound.
	 * @param	y				The Y position of the sound.
	 * @param	target			The object you want to track.
	 * @param	radius			The maximum distance this sound can travel.
	 * @param	pan				Whether panning should be used in addition to the volume changes.
	 * @param	scrollFactor	Whether scrollfactor should be used in addition to the volume changes.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function proximity(x = 0.0, y = 0.0, ?target:FlxObject, ?radius:Float, pan = true, ?scrollFactor:FlxPoint):FlxSound
	{
		proximityEnabled = true;
		proximityPan = pan;

		setPosition(x, y);
		if (target != null) this.target = target;
		if (radius != null) this.radius = radius;
		if (scrollFactor != null) this.scrollFactor.copyFrom(scrollFactor);
		else if (this.scrollFactor == null) this.scrollFactor = FlxPoint.get(0, 0);

		return this;
	}

	/**
	 * Call this function to play the sound - also works on paused sounds.
	 *
	 * @param	forceRestart	Whether to start the sound over or not.
	 *							Default value is false, meaning if the sound is already playing or was
	 *							paused when you call play(), it will continue playing from its current
	 *							position, NOT start again from the beginning.
	 * @param	startTime		At which point to start playing the sound, in milliseconds.
	 * @param	endTime			At which point to stop playing the sound, in milliseconds.
	 *							If not set / `null`, it'll be the same as previous set of endTime.
	 * @param	volume			What volume should the audio be played with.
	 * @param	pitch			What pitch should the audio be played with (NOTE: Flash does not support this).
	 * @param	pan				What pan should the audio be played with.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function play(forceRestart = false, startTime = 0.0, ?endTime:Float, ?volume:Float, ?pitch:Float, ?pan:Float):FlxSound
	{
		if (volume != null) _volume = volume;
		#if FLX_PITCH
		if (pitch != null) _pitch = pitch;
		#end
		if (pan != null) _pan = pan;
		if (endTime != null) this.endTime = endTime;

		if (!loaded || (playing && !forceRestart)) return this;

		_updateVolume();
		#if FLX_PITCH
		_updatePitch();
		#end
		_updatePan();
		_updateLoop();

		if (!_paused) loopCount = 0;
		if (!_paused || forceRestart) source.currentTime = startTime + offset;

		if (_pausedByHandler) _pausedPlay = true;
		else if (!source.playing) source.play();

		_paused = false;
		_completed = false;
		active = true;

		return this;
	}

	/**
	 * Call this function to prepare the sound in specific time, then call `resume()` or `FlxSound.playSounds()`.
	 * Good for playing multiple sounds at the same time, stops completely and override pause status.
	 * 
	 * @param	startTime		At which point to start playing the sound, in milliseconds.
	 * @param	endTime			At which point to stop playing the sound, in milliseconds.
	 *							If not set / `null`, it'll be the same as previous set of endTime.
	 * @param	volume			What volume should the audio be played with.
	 * @param	pitch			What pitch should the audio be played with (NOTE: Flash does not support this).
	 * @param	pan				What pan should the audio be played with.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function prepare(startTime = 0.0, ?endTime:Float, ?volume:Float, ?pitch:Float, ?pan:Float):FlxSound
	{
		if (volume != null) _volume = volume;
		#if FLX_PITCH
		if (pitch != null) _pitch = pitch;
		#end
		if (pan != null) _pan = pan;
		if (endTime != null) this.endTime = endTime;

		if (!loaded) return this;

		_updateVolume();
		#if FLX_PITCH
		_updatePitch();
		#end
		_updatePan();
		_updateLoop();

		source.prepare(startTime + offset);

		_paused = true;
		_completed = false;
		active = false;

		return this;
	}

	/**
	 * Unpause a sound. Only works on sounds that have been paused.
	 * 
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function resume():FlxSound
	{
		if (_paused) play(false);
		return this;
	}

	/**
	 * Call this function to pause this sound.
	 * 
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function pause():FlxSound
	{
		source.pause();

		get_time();
		_timeTicks = null;
		_pausedByHandler = false;
		_pausedPlay = false;
		_paused = true;
		active = false;

		return this;
	}

	/**
	 * Call this function to stop this sound.
	 * 
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function stop():FlxSound
	{
		_timeTicks = null;
		_pausedByHandler = false;
		_pausedPlay = false;
		_paused = true;
		active = false;

		source.stop();
		if (autoDestroy) kill();

		return this;
	}

	/**
	 * Helper function that tweens this sound's volume.
	 *
	 * @param	duration	The amount of time the fade-out operation should take.
	 * @param	to			The volume to tween to, 0 by default.
	 * @param	onComplete	The callback for when it's done fading.
	 * @param	ease		EaseFunction to use for the tween.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function fadeOut(duration = 1.0, to = 0.0, ?onComplete:FlxTween->Void, ?ease:EaseFunction):FlxSound
	{
		fadeTween?.cancel();
		fadeTween = FlxTween.num(_volume, to, duration, {ease: ease ?? FlxEase.quadIn, onComplete: onComplete}, volumeTween);

		return this;
	}

	/**
	 * Helper function that tweens this sound's volume.
	 * If the sound wasn't playing at all, it'll play before the tween starts.
	 *
	 * @param	duration	The amount of time the fade-in operation should take.
	 * @param	from		The volume to tween from, 0 by default.
	 * @param	to			The volume to tween to, 1 by default.
	 * @param	onComplete	The callback for when it's done fading.
	 * @param	ease		EaseFunction to use for the tween.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function fadeIn(duration = 1.0, from = 0.0, to = 1.0, ?onComplete:FlxTween->Void, ?ease:EaseFunction):FlxSound
	{
		if (!playing) play();

		fadeTween?.cancel();
		fadeTween = FlxTween.num(from, to, duration, {ease: ease ?? FlxEase.quadOut, onComplete: onComplete}, volumeTween);

		return this;
	}

	function volumeTween(f:Float) volume = f;

	/**
	 * Adds an audio playback effect for this sound.
	 * 
	 * @param	effect	A `lime.media.AudioEffect` instance.
	 * @since FunkinCrew's Flixel & Lime
	 */
	public function addEffect(effect:AudioEffect):Void
	{
		source.addEffect(effect);
	}

	/**
	 * Removes an audio playback effect from this sound.
	 * 
	 * @param	effect	A `lime.media.AudioEffect` instance.
	 * @since FunkinCrew's Flixel & Lime
	 */
	public function removeEffect(effect:AudioEffect):Void
	{
		source.removeEffect(effect);
	}

	/**
	 * Clears any existing audio playback effects added in this sound.
	 * @since FunkinCrew's Flixel & Lime
	 */
	public function clearEffects():Void
	{
		source.clearEffects();
	}

	/**
	 * Returns the audio playback effect stred at the specified index.
	 * 
	 * @param	index	An index to the `lime.media.AudioEffect`.
	 * @return	The specified `lime.media.AudioEffect` from the index.
	 * @since FunkinCrew's Flixel & Lime
	 */
	public function getEffectAt(index:Int):AudioEffect
	{
		return source.getEffectAt(index);
	}

	/**
	 * Returns the index of a desired audio playback effect stored.
	 * 
	 * @param	effect	A `lime.media.AudioEffect` instance.
	 * @return	The index stored for the desired audio playback effect in this sound.
	 * @since FunkinCrew's Flixel & Lime
	 */
	public function getEffectIndex(effect:AudioEffect):Int
	{
		return source.getEffectIndex(effect);
	}

	/**
	 * Returns the currently selected "real" volume of the sound (takes fades and proximity).
	 * 
	 * @return	The adjusted volume of the sound.
	 */
	public function getActualVolume():Float
	{
		return if (_muted) 0; else (group != null ? group.getVolume() : 1.0) * _volume * _volumeAdjust;
	}

	#if FLX_PITCH
	/**
	 * Returns the currently selected "real" pitch of the sound.
	 * 
	 * @return	The adjusted pitch of the sound.
	 */
	public function getActualPitch():Float
	{
		return if (_timeScaledPitch) _pitch * FlxG.timeScale; else _pitch;
	}
	#end

	/**
	 * Returns the currently selected "real" pan of the sound (takes fades and proximity).
	 * 
	 * @return	The adjusted pan of the sound.
	 */
	public function getActualPan():Float
	{
		return _pan + _panAdjust;
	}

	/**
	 * Returns the actual time coming from the internal, can be used for detecting sync error.
	 * 
	 * @return	The actual time of the sound.
	 */
	public function getActualTime():Float
	{
		get_time();
		return _lastTime;
	}

	function stopped():Void
	{
		if (onComplete != null) onComplete();
		onFinish.dispatch();

		if (_looped)
		{
			_timeInterpolation = 1;
			_timeTicks = FlxG.game.getTicks();
			_lastTime = loopTime;
			loopCount++;
			_updateLoop();
		}
		else
		{
			_completed = true;
			if (autoDestroy) kill();
		}
	}

	function set_group(value:FlxSoundGroup):FlxSoundGroup
	{
		if (value != null) value.add(this);
		else group.remove(this);
		return group;
	}

	function set_proximityEnabled(value:Bool):Bool
	{
		if (proximityEnabled != value && !value)
		{
			proximityEnabled = value;

			_volumeAdjust = 1;
			//_pitchAdjust = 1;
			_panAdjust = 0;
			_updateVolume();
			//_updatePitch();
			_updatePan();
		}

		return value;
	}

	function set_proximityPan(value:Bool):Bool
	{
		if (proximityPan != value && proximityEnabled && !value)
		{
			proximityPan = value;

			_panAdjust = 0;
			_updatePan();
		}

		return value;
	}

	function get_playing():Bool
	{
		return loaded && source.playing || _pausedPlay;
	}

	function get_paused():Bool
	{
		return _paused;
	}

	function get_completed():Bool
	{
		return _completed;
	}

	function get_volume():Float
	{
		return _volume;
	}

	function set_volume(value:Float):Float
	{
		value = Math.max(value, 0);
		if (_volume != value)
		{
			_volume = value;
			_updateVolume();
		}

		return value;
	}

	function get_muted():Bool
	{
		return _muted;
	}

	function set_muted(value:Bool):Bool
	{
		if (_muted != value)
		{
			_muted = value;
			_updateVolume();
		}

		return value;
	}

	#if FLX_PITCH
	function get_pitch():Float
	{
		return _pitch;
	}

	function set_pitch(value:Float):Float
	{
		value = Math.max(value, 0);
		if (_pitch != value)
		{
			_pitch = value;
			_updatePitch();
		}

		return value;
	}

	function get_timeScaledPitch():Bool
	{
		return _timeScaledPitch;
	}

	function set_timeScaledPitch(value:Bool):Bool
	{
		if (_timeScaledPitch != value)
		{
			_timeScaledPitch = value;
			_updatePitch();
		}

		return value;
	}
	#end

	function get_pan():Float
	{
		return _pan;
	}

	function set_pan(value:Float):Float
	{
		value = FlxMath.bound(value, -1, 1);
		if (_pan != value)
		{
			_pan = value;
			_updatePan();
		}

		return value;
	}

	function get_length():Float
	{
		return loaded ? data.length - offset : 0;
	}

	function get_looped():Bool
	{
		return _looped;
	}

	function set_looped(value:Bool):Bool
	{
		if (_looped != value)
		{
			_looped = value;
			_updateLoop();
		}

		return value;
	}

	function set_loopUntil(value:Int):Int
	{
		value = value < 0 ? -1 : value;
		if (loopUntil != value)
		{
			loopUntil = value;
			_updateLoop();
		}

		return value;
	}

	function get_loopTime():Float
	{
		return _loopTime - offset;
	}

	function set_loopTime(value:Float):Float
	{
		value = loaded ? FlxMath.bound(value, -offset, data.length - offset) : -offset;

		var internal = value + offset;
		if (_loopTime != internal)
		{
			_loopTime = internal;
			source.loopTime = internal;
		}

		return value;
	}

	function get_endTime():Null<Float>
	{
		return _endTime == null ? null : _endTime - offset;
	}

	function set_endTime(value:Null<Float>):Null<Float>
	{
		value = (loaded && value != null && value > -offset) ? Math.min(value, data.length - offset) : null;

		var internal = value == null ? null : value + offset;
		if (_endTime != internal)
		{
			_endTime = internal;
			if (internal == null) source.length = length;
			else source.length = internal;
		}

		return value;
	}

	function get_time():Float
	{
		if (!loaded) return 0.0;
		else if (_completed) return source.length - offset;

		final currentTime = source.currentTime - offset;
		if (!source.playing)
		{
			_timeTicks = null;
			return _lastTime = currentTime;
		}
		else if (_timeTicks == null)
		{
			_timeTicks = FlxG.game.getTicks();
			_timeInterpolation = 1.0;
			return _lastTime = currentTime;
		}

		final interpolatedTime = _lastTime + (FlxG.game.getTicks() - _timeTicks) * source.pitch * _timeInterpolation;
		if (_lastTime != currentTime)
		{
			_timeTicks = FlxG.game.getTicks();
			if ((_timeInterpolation = 1.0 - (interpolatedTime - currentTime) * 0.001) < 1.0 && _timeInterpolation > 0.9)
			{
				return _lastTime = interpolatedTime;
			}
			else
			{
				_timeInterpolation = 1.0;
				return _lastTime = currentTime;
			}
		}

		return interpolatedTime;
	}

	function set_time(value:Float):Float
	{
		_timeTicks = null;
		value = FlxMath.bound(value, -offset, source.length - offset);

		if (loaded) source.currentTime = value + offset;
		else _lastTime = 0;

		return value;
	}

	function get_latency():Float
	{
		return source.latency;
	}

	function get_amplitude():Float
	{
		if (!_amplitudeUpdated) _updateAmplitudes();
		return _amplitude;
	}

	function get_amplitudes():Array<Float>
	{
		if (!_amplitudeUpdated) _updateAmplitudes();
		return _amplitudes;
	}

	function get_amplitudeLeft():Float
	{
		if (!_amplitudeUpdated) _updateAmplitudes();
		return _amplitudes[0] ?? 0;
	}

	function get_amplitudeRight():Float
	{
		if (!_amplitudeUpdated) _updateAmplitudes();
		return _amplitudes[1] ?? 0;
	}

	function updateTransform():Void
	{
		_updateVolume();
		#if FLX_PITCH
		_updatePitch();
		#end
		_updatePan();
	}

	@:allow(flixel.sound.FlxSoundGroup)
	function _updateVolume():Void
	{
		if (_muted || FlxG.sound._muted) source.gain = 0;
		else source.gain = calcTransformVolume();
	}

	function calcTransformVolume():Float
	{
		#if FLX_SOUND_SYSTEM
		if (FlxG.sound._muted) return 0;
		return FlxG.sound.applySoundCurve(getActualVolume() * FlxG.sound._volume);
		#else
		return getActualVolume();
		#end
	}

	#if FLX_PITCH
	function _updatePitch():Void
	{
		source.pitch = getActualPitch();
	}
	#end

	function _updatePan():Void
	{
		source.pan = getActualPan();
	}

	function _updateLoop():Void
	{
		if (_looped)
		{
			if (loopUntil == -1) source.loops = 999;
			else
			{
				var internal = loopUntil - loopCount;
				if (internal != source.loops) source.loops = internal;
			}
		}
		else source.loops = 0;
	}

	function _updateAmplitudes():Void
	{
		if (!loaded) return;

		_amplitudeUpdated = true;
		_amplitude = 0;

		final peaks = source.peaks;
		for (i in 0...peaks.length)
		{
			_amplitudes[i] = peaks[i];
			if (peaks[i] > _amplitude) _amplitude = peaks[i];
		}
	}

	override public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("playing", playing),
			LabelValuePair.weak("time", time),
			LabelValuePair.weak("offset", offset),
			LabelValuePair.weak("length", length),
			LabelValuePair.weak("volume", volume),
			#if FLX_PITCH
			LabelValuePair.weak("pitch", pitch)
			#end
		]);
	}
}