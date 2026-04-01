package flixel.sound;

import haxe.io.Bytes;
import haxe.Int64;

import lime.media.AudioBuffer;
import lime.media.AudioContextType;
import lime.media.AudioDecoder;
import lime.media.AudioManager;

import openfl.media.Sound;
import openfl.utils.Assets;
import openfl.utils.ByteArray;

import flixel.system.FlxAssets;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxStringUtil;

/**
 * Lime `AudioBuffer` wrapper which is used for audio.
 * @since FunkinCrew's Flixel
 */
@:access(lime.media.AudioBuffer)
@:access(openfl.media.Sound)
@:access(flixel.system.frontEnds.AssetFrontEnd)
class FlxSoundData implements IFlxDestroyable
{
	/**
	 * What minimum of duration or length in milliseconds can it be automatically be persists.
	 */
	public static var persistMaxDuration:Float = 3000;

	/**
	 * How much duration or length in milliseconds can it be automatically be assigned
	 * to be a streamed sound data.
	 */
	public static var streamMinimumLength:Float = 8000;

	/**
	 * Should it allow streaming when stream argument to load `FlxSoundData` is not set.
	 */
	public static var allowStreaming:Bool = true;

	/**
	 * Creates and caches FlxSoundData object from source asset.
	 * 
	 * @param   asset	`FlxSoundAsset` to load.
	 * @param	stream	Load this sound data to be streamable instead.
	 * @param   key		Force the cache to use a specific key to index the sound data.
	 * @param   cache	Whether to use sound data caching or not. Default value is `true`, which means automatic caching.
	 * @return  Cached	`FlxSoundData` object we just created.
	 */
	public static function fromAsset(asset:FlxSoundAsset, ?stream:Bool, ?key:String, cache = true):FlxSoundData
	{
		if ((asset is Class)) return fromClass(cast asset, key, cache);
		else if ((asset is String)) return fromAssetKey(cast asset, stream, key, cache);
		else if ((asset is Bytes)) return fromByteArray(cast asset, stream, key, cache);
		else if ((asset is Sound)) return fromSound(cast asset, key, cache);
		else if ((asset is AudioBuffer)) return fromAudioBuffer(cast asset, key, cache);
		else if ((asset is FlxSoundData)) return cast asset;

		return null;
	}

	/**
	 * Creates and caches FlxSoundData object from openfl.Assets key string.
	 * 
	 * @param   source	`openfl.Assets` key string. For example: `"assets/sound.mp3"`.
	 * @param	stream	Load this sound data to be streamable instead.
	 * @param   key		Force the cache to use a specific key to index the sound data.
	 * @param   cache	Whether to use sound data caching or not. Default value is `true`, which means automatic caching.
	 * @return  Cached	`FlxSoundData` object we just created.
	 */
	public static function fromAssetKey(source:String, ?stream:Bool, ?key:String, cache = true):FlxSoundData
	{
		if (key == null) key = source;

		#if FLX_SOUND_SYSTEM
		if (cache)
		{
			var soundData = FlxG.sound.getCache(key);
			if (soundData != null) return soundData;
		}
		#end

		final openflAssetExists = Assets.exists(source);

		#if native
		var decoder = AudioDecoder.fromFile(openflAssetExists ? Assets.getPath(source) : source);
		if (decoder == null)
		{
			if (!openflAssetExists) return null;

			decoder = AudioDecoder.fromBytes(Assets.getBytes(source));
			if (decoder == null) return null;
		}

		if (stream == null) stream = allowStreaming && decoder.total() >= Std.int(streamMinimumLength / 1000.0 * decoder.sampleRate);
		return fromAudioBuffer(AudioBuffer.fromDecoder(decoder, stream, true), key, cache);
		#else
		var buffer = AudioBuffer.fromFile(openflAssetExists ? Assets.getPath(source) : source);
		if (buffer == null)
		{
			if (!openflAssetExists) return null;

			buffer = AudioBuffer.fromBytes(Assets.getBytes(source));
			if (buffer == null) return null;
		}

		return fromAudioBuffer(buffer, key, cache);
		#end
	}

	/**
	 * Creates and caches `FlxSoundData` object from a compressed byte array object.
	 *
	 * @param   source	`ByteArray` for `FlxSoundData` to use.
	 * @param	stream	Load this sound data to be streamable instead.
	 * @param   key		Force the cache to use a specific key to index the sound data.
	 * @param   cache	Whether to use sound data caching or not. Default value is `true`, which means automatic caching.
	 * @return  Cached	`FlxSoundData` object we just created.
	 */
	public static function fromByteArray(source:Bytes, ?stream:Bool, ?key:String, cache = true):FlxSoundData
	{
		#if FLX_SOUND_SYSTEM
		if (cache && key != null)
		{
			var soundData = FlxG.sound.getCache(key);
			if (soundData != null) return soundData;
		}
		#end

		if (source == null) return null;

		#if native
		final decoder = AudioDecoder.fromBytes(cast source);
		if (decoder == null) return null;

		if (stream == null) stream = allowStreaming && decoder.total() >= Std.int(streamMinimumLength / 1000.0 * decoder.sampleRate);
		return fromAudioBuffer(AudioBuffer.fromDecoder(decoder, stream, true), key, cache);
		#else
		return fromAudioBuffer(AudioBuffer.fromBytes(cast source, stream), key, cache);
		#end
	}

	/**
	 * Creates and caches FlxSoundData object from a specified `Class<Sound>`.
	 * 
	 * @param   source	`Class<Sound>` to create `Sound` for `FlxSoundData` from.
	 * @param   key		Force the cache to use a specific key to index the sound data.
	 * @param   cache	Whether to use sound data caching or not. Default value is `true`, which means automatic caching.
	 * @return  Cached	`FlxSoundData` object we just created.
	 */
	public static function fromClass(source:Class<Sound>, ?key:String, cache = true):FlxSoundData
	{
		#if FLX_SOUND_SYSTEM
		if (cache && key != null)
		{
			var soundData = FlxG.sound.getCache(key);
			if (soundData != null) return soundData;
		}
		#end

		if (source == null) return null;

		var instance = Type.createInstance(source, []);
		if ((instance is Sound)) return fromSound(cast instance, key, cache);
		else if ((instance is AudioBuffer)) return fromAudioBuffer(cast instance, key, cache);

		return null;
	}

	/**
	 * Creates and caches `FlxSoundData` object from specified `Sound` object.
	 *
	 * @param   source	`Sound` for `FlxSoundData` to use.
	 * @param   key		Force the cache to use a specific key to index the sound data.
	 * @param   cache	Whether to use sound data caching or not. Default value is `true`, which means automatic caching.
	 * @return  Cached	`FlxSoundData` object we just created.
	 */
	public static function fromSound(source:Sound, ?key:String, cache = true):FlxSoundData
	{
		#if FLX_SOUND_SYSTEM
		if (cache && key != null)
		{
			var soundData = FlxG.sound.getCache(key);
			if (soundData != null) return soundData;
		}
		#end

		// Maybe make it also load pending buffer too...?
		if (source == null || source.__buffer == null) return null;

		return fromAudioBuffer(source.__buffer, key, cache);
	}

	/**
	 * Creates and caches `FlxSoundData` object from specified `AudioBuffer` object.
	 *
	 * @param   source	`AudioBuffer` for `FlxSoundData` to use.
	 * @param   key		Force the cache to use a specific key to index the sound data.
	 * @param   cache	Whether to use sound data caching or not. Default value is `true`, which means automatic caching.
	 * @return  Cached	`FlxSoundData` object we just created.
	 */
	public static function fromAudioBuffer(source:AudioBuffer, ?key:String, cache = true):FlxSoundData
	{
		if (source == null) return null;
		else if (!cache) return createSoundData(source, key, false);

		#if FLX_SOUND_SYSTEM
		var localKey:String = FlxG.sound.findKeyForBuffer(source);
		if (localKey != null && key == null) return FlxG.sound.getCache(localKey);
		#end

		#if FLX_SOUND_SYSTEM
		if (key == null) key = generateKey();
		#end
		return createSoundData(source, key, cache);
	}

	#if FLX_SOUND_SYSTEM
	static var _lastUniqueKeyIndex:Int = 0;
	static function generateKey():String
	{
		var baseKey = "soundData";
		var i:Int = _lastUniqueKeyIndex;
		var uniqueKey:String;
		do
		{
			i++;
			uniqueKey = baseKey + i;
		}
		while (FlxG.sound.checkCache(uniqueKey));

		_lastUniqueKeyIndex = i;
		return uniqueKey;
	}
	#end

	static function createSoundData(buffer:AudioBuffer, ?key:String, cache = true):FlxSoundData
	{
		var soundData:FlxSoundData = null;

		if (cache && key != null)
		{
			soundData = new FlxSoundData(key, buffer);
			#if FLX_SOUND_SYSTEM
			FlxG.sound.addCache(soundData);
			#end
		}
		else
		{
			soundData = new FlxSoundData(null, buffer);
		}

		return soundData;
	}

	/**
	 * Key used in the `SoundFrontEnd` cache.
	 */
	public var key(default, null):String;

	/**
	 * Whether this sound data object should stay in the cache after state changes or not.
	 * `destroyOnNoUse` has no effect when this is set to `true`.
	 */
	public var persist:Bool = false;

	/**
	 * Whether this `FlxSoundData` should be immediately destroyed when `useCount` becomes zero (defaults to `false`).
	 * Ignores `unused`, has no effect when `persist` is `true`.
	 */
	public var destroyOnNoUse(default, set):Bool = false;

	/**
	 * Usage counter for this `FlxSoundData` object.
	 */
	public var useCount(default, null):Int = 0;

	/**
	 * Whether or not is it about to be destroyed in the next clearing cycle.
	 */
	#if FLX_SOUND_SYSTEM
	@:allow(flixel.system.frontEnds.SoundFrontEnd)
	#end
	public var unused(default, null):Bool;

	/**
	 * The number of bits per sample in the sound data.
	 */
	public var bitsPerSample(get, never):Int;

	/**
	 * The Lime `AudioBuffer` for FlxSound to play.
	 */
	public var buffer(get, set):AudioBuffer;

	/**
	 * The number of sound data channels.
	 * (1 for mono, 2 for stereo, etc).
	 */
	public var channels(get, never):Int;

	/**
	 * The sample rate of the sound data, in Hz.
	 */
	public var sampleRate(get, never):Int;

	/**
	 * How much samples are in this sound data.
	 */
	public var samples(get, never):Int64;

	/**
	 * The duration or length in millseconds of this sound data.
	 */
	public var length(get, never):Float;

	/**
	 * Whether `destroy` was called on this sound data.
	 */
	public var isDestroyed(get, never):Bool;

	/**
	 * Is this sound data is streamable.
	 */
	public var isStreamable(get, never):Bool;

	var _buffer:AudioBuffer;
	#if native
	var _samples:Int64;
	#end

	/**
	 * `FlxSoundData` contructor
	 */
	public function new(key:String, buffer:AudioBuffer, ?persist:Bool)
	{
		this.key = key;
		this.buffer = buffer;

		if (persist == null) persist = buffer != null && get_length() < persistMaxDuration;
		this.persist = persist;
	}

	/**
	 * Free this `FlxSoundData` object from memory.
	 */
	public function destroy():Void
	{
		#if FLX_SOUND_SYSTEM
		if (key != null) FlxG.sound.removeCache(key, false);
		#end
		if (_buffer != null) _buffer.dispose();
		_buffer = null;
	}

	public function incrementUseCount()
	{
		useCount++;

		unused = false;
	}
	
	public function decrementUseCount()
	{
		useCount--;
		
		checkUseCount();
	}
	
	function checkUseCount()
	{
		#if FLX_SOUND_SYSTEM
		if (useCount <= 0 && destroyOnNoUse && !persist) destroy();
		#end
	}

	inline function get_bitsPerSample():Int
	{
		#if (js && html5 && howlerjs)
		if (_buffer != null && _buffer.bitsPerSample > 0) return _buffer.bitsPerSample;
		return 16;
		#else
		return _buffer != null ? _buffer.bitsPerSample : 0;
		#end
	}

	inline function get_channels():Int
	{
		#if (js && html5 && howlerjs)
		if (_buffer != null && _buffer.channels > 0) return _buffer.channels;
		return 2;
		#else
		return _buffer != null ? _buffer.channels : 0;
		#end
	}

	function get_sampleRate():Int
	{
		#if (js && html5 && howlerjs)
		if (_buffer != null && _buffer.sampleRate > 0) return _buffer.sampleRate;
		else if (AudioManager.context != null && AudioManager.context.type == AudioContextType.WEB) return Std.int(AudioManager.context.web.sampleRate);
		return 44100;
		#else
		return _buffer != null ? _buffer.sampleRate : 0;
		#end
	}

	function get_samples():Int64
	{
		#if (js && html5 && howlerjs)
		return (_buffer != null && _buffer.__srcHowl != null) ? Int64.fromFloat(_buffer.__srcHowl.duration() * get_sampleRate()) : 0;
		#else
		return _buffer != null ? _samples : 0;
		#end
	}

	function get_length():Float
	{
		#if (js && html5 && howlerjs)
		return (_buffer?.__srcHowl?.duration() ?? 0) * 1000.0;
		#else
		return _buffer != null ? (_samples.high * 4294967296.0 + (_samples.low >>> 0)) / _buffer.sampleRate * 1000.0 : 0;
		#end
	}

	inline function get_isDestroyed():Bool
	{
		return _buffer == null;
	}

	inline function get_isStreamable():Bool
	{
		return _buffer != null && _buffer.data == null && _buffer.decoder != null;
	}

	inline function set_destroyOnNoUse(value:Bool):Bool
	{
		this.destroyOnNoUse = value;
		
		checkUseCount();
		
		return value;
	}

	inline function get_buffer():AudioBuffer
	{
		return _buffer;
	}

	function set_buffer(value:AudioBuffer):AudioBuffer
	{
		if (_buffer != value && value != null)
		{
			#if native
			if (value.decoder != null) _samples = value.decoder.total();
			else if (value.data != null) _samples = Int64.make(0, Std.int(value.data.length / (value.bitsPerSample >> 3) / value.channels));
			else _samples = 0;
			#end
		}
		return _buffer = value;
	}

	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("key", key),
			LabelValuePair.weak("useCount", useCount),
			LabelValuePair.weak("bitsPerSample", bitsPerSample),
			LabelValuePair.weak("channels", channels),
			LabelValuePair.weak("sampleRate", sampleRate),
			LabelValuePair.weak("length", length)
		]);
	}
}