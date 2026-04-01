package flixel.system.frontEnds;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.sound.FlxSoundData;
import flixel.sound.FlxSoundGroup;
import flixel.system.FlxAssets;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxInputText;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxSignal;
#if FLX_SAVE
import flixel.util.FlxSave;
#end
import openfl.media.Sound;
import openfl.utils.Assets;
import lime.media.AudioManager;
import lime.media.AudioBuffer;
import haxe.io.Bytes;

/**
 * Accessed via `FlxG.sound`.
 */
@:allow(flixel.sound.FlxSound)
@:allow(flixel.FlxG)
class SoundFrontEnd
{
	#if FLX_SAVE
	public static var save(get, null):FlxSave;

	static function get_save():FlxSave
	{
		if (save == null || !save.isBound)
			save = FlxG.save;
		return save;
	}
	#end

	/**
	 * How much sounds to keep in the list after clearing between states.
	 * 
	 * @since FunkinCrew's Flixel
	 */
	public static var poolMaxSounds:Int = 16;

	/**
	 * A handy container for a background music object.
	 */
	public var music:FlxSound;

	/**
	 * Whether or not should it automatically switch to a new default playback device if detected.
	 */
	public var automaticDefaultDevice(get, set):Bool;

	/**
	 * The current used playback device name to play audios.
	 */
	public var deviceName(get, set):String;

	/**
	 * Set this to a number between 0 and 1 to change the global volume.
	 */
	public var volume(get, set):Float;

	/**
	 * Whether or not the game sounds are muted.
	 */
	public var muted(get, set):Bool;

	/**
	 * A Read only variable to check if it's paused or not.
	 */
	public var paused(default, null):Bool = false;

	/**
	 * Set this hook to get a callback whenever the volume changes.
	 * Function should take the form myVolumeHandler(volume:Float).
	 */
	//@:deprecated("volumeHandler is deprecated, use onVolumeChange instead")
	public var volumeHandler:Float->Void;

	/**
	 * A signal that gets dispatched whenever the volume changes.
	 */
	public var onVolumeChange(default, null):FlxTypedSignal<Float->Void> = new FlxTypedSignal<Float->Void>();

	/**
	 * Dispatched when the default for the playback device is changed.
	 */
	public var onDefaultDeviceChanged(default, null):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	/**
	 * Dispatched whenever a playback device is added.
	 */
	public var onDeviceAdded(default, null):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	/**
	 * Dispatched whenever a playbck device is removed.
	 */
	public var onDeviceRemoved(default, null):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	#if FLX_KEYBOARD
	/**
	 * Wether volume control by keys is allowed
	 */
	public var keysAllowed:Bool = true;

	/**
	 * The key codes used to increase volume (see FlxG.keys for the keys available).
	 * Default keys: + (and numpad +). Set to null to deactivate.
	 */
	public var volumeUpKeys:Array<FlxKey> = [PLUS, NUMPADPLUS];

	/**
	 * The keys to decrease volume (see FlxG.keys for the keys available).
	 * Default keys: - (and numpad -). Set to null to deactivate.
	 */
	public var volumeDownKeys:Array<FlxKey> = [MINUS, NUMPADMINUS];

	/**
	 * The keys used to mute / unmute the game (see FlxG.keys for the keys available).
	 * Default keys: 0 (and numpad 0). Set to null to deactivate.
	 */
	public var muteKeys:Array<FlxKey> = [ZERO, NUMPADZERO];
	#end

	/**
	 * Whether or not the soundTray should be shown when any of the
	 * volumeUp-, volumeDown- or muteKeys is pressed.
	 */
	public var soundTrayEnabled:Bool = true;
	
	#if FLX_SOUND_TRAY
	/**
	 * The sound tray display container.
	 * A getter for `FlxG.game.soundTray`.
	 */
	public var soundTray(get, never):FlxSoundTray;
	
	inline function get_soundTray()
	{
		return FlxG.game.soundTray;
	}
	#end

	/**
	 * The group sounds played via playMusic() are added to unless specified otherwise.
	 */
	public var defaultMusicGroup:FlxSoundGroup = new FlxSoundGroup();

	/**
	 * The group sounds in load() / play() / stream() are added to unless specified otherwise.
	 */
	public var defaultSoundGroup:FlxSoundGroup = new FlxSoundGroup();

	/**
	 * A list of all the sounds being played in the game.
	 */
	public var list(default, null):FlxTypedGroup<FlxSound> = new FlxTypedGroup<FlxSound>();

	/**
	 * Whether or not can it be paused on lost focus (if FlxG.autoPause is true).
	 */
	public var canAutoPause:Bool = true;

	var _volume:Float = 1.0;
	var _muted:Bool = false;
	var _lastTimeScale:Float;
	var _lostFocusPause:Bool;
	var _cache:Map<String, FlxSoundData>;

	/**
	 * Set up and play a looping background soundtrack.
	 *
	 * **Note:** If the `FLX_DEFAULT_SOUND_EXT` flag is enabled, you may omit the file extension
	 *
	 * @param   embeddedMusic  The sound file you want to loop in the background.
	 * @param   volume         How loud the sound should be, from 0 to 1.
	 * @param   looped         Whether to loop this music.
	 * @param   group          The group to add this sound to.
	 */
	public function playMusic(embeddedMusic:FlxSoundAsset, volume = 1.0, looped = true, ?group:FlxSoundGroup):Void
	{
		if (group == null)
			group = defaultMusicGroup;
		
		if (music == null)
		{
			music = new FlxSound();
		}
		else if (music.active)
		{
			music.stop();
		}
		
		music.loadEmbedded(embeddedMusic, looped);
		music.volume = volume;
		music.persist = true;
		group.add(music);
		music.play();
	}

	/**
	 * Creates a new FlxSound object.
	 *
	 * **Note:** If the `FLX_DEFAULT_SOUND_EXT` flag is enabled, you may omit the file extension
	 *
	 * @param   embeddedSound   The embedded sound resource you want to play.  To stream, use the optional URL parameter instead.
	 * @param   volume          How loud to play it (0 to 1).
	 * @param   looped          Whether to loop this sound.
	 * @param   group           The group to add this sound to.
	 * @param   autoDestroy     Whether to destroy this sound when it finishes playing.
	 *                          Leave this value set to "false" if you want to re-use this FlxSound instance.
	 * @param   autoPlay        Whether to play the sound.
	 * @param   url             Load a sound from an external web resource instead.  Only used if EmbeddedSound = null.
	 * @param   onComplete      Called when the sound finished playing.
	 * @param   onLoad          Called when the sound finished loading.  Called immediately for succesfully loaded embedded sounds.
	 * @return  A FlxSound object.
	 */
	public function load(?embeddedSound:FlxSoundAsset, volume = 1.0, looped = false, ?group:FlxSoundGroup, autoDestroy = false, autoPlay = false, ?url:String,
			?onComplete:Void->Void, ?onLoad:Void->Void):FlxSound
	{
		if ((embeddedSound == null) && (url == null))
		{
			FlxG.log.warn("FlxG.sound.load() requires either\nan embedded sound or a URL to work.");
			return null;
		}

		var sound:FlxSound = list.recycle(FlxSound);

		if (embeddedSound != null)
		{
			sound.loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);
			loadHelper(sound, volume, group, autoPlay);
			// Call OnlLoad() because the sound already loaded
			if (onLoad != null && sound.data != null)
				onLoad();
		}
		else
		{
			var loadCallback = onLoad;
			if (autoPlay)
			{
				// Auto play the sound when it's done loading
				loadCallback = function()
				{
					sound.play();

					if (onLoad != null)
						onLoad();
				}
			}

			sound.loadFromURL(url, looped, autoDestroy, onComplete, loadCallback);
			loadHelper(sound, volume, group);
		}

		return sound;
	}

	function loadHelper(sound:FlxSound, volume:Float, group:FlxSoundGroup, autoPlay = false):FlxSound
	{
		if (group == null) group = defaultSoundGroup;
		
		sound.volume = volume;
		group.add(sound);
		
		if (autoPlay)
			sound.play();
		
		return sound;
	}

	@:deprecated("Don't use this, a deprecated CNE modification function")
	inline function destroySound(sound:FlxSound):Void
	{
		defaultMusicGroup.remove(sound);
		defaultSoundGroup.remove(sound);
		// defaultMusicGroup.remove(sound);
		// defaultSoundGroup.remove(sound);
		sound.destroy();
	}

	/**
	 * Method for sound caching (especially useful on mobile targets). The game may freeze
	 * for some time the first time you try to play a sound if you don't use this method.
	 *
	 * @param   embeddedSound  Name of sound assets specified in your .xml project file
	 * @return  Cached Sound object
	 */
	@:deprecated("cache() is deprecated, use FlxSoundData.fromAsset() instead.")
	public inline function cache(embeddedSound:String):Sound
	{
		// load the sound into the OpenFL assets cache
		if (FlxG.assets.exists(embeddedSound, SOUND))
			return FlxG.assets.getSoundUnsafe(embeddedSound, true);
		FlxG.log.error('Could not find a Sound asset with an ID of \'$embeddedSound\'.');
		return null;
	}

	/**
	 * Calls FlxG.sound.cache() on all sounds that are embedded.
	 * WARNING: can lead to high memory usage.
	 */
	public function cacheAll():Void
	{
		for (id in FlxG.assets.list(SOUND))
		{
			FlxSoundData.fromAssetKey(id);
		}
	}

	/**
	 * Plays a sound from an embedded sound. Tries to recycle a cached sound first.
	 *
	 * **Note:** If the `FLX_DEFAULT_SOUND_EXT` flag is enabled, you may omit the file extension
	 *
	 * @param   embeddedSound  The embedded sound resource you want to play.
	 * @param   volume         How loud to play it (0 to 1).
	 * @param   looped         Whether to loop this sound.
	 * @param   group          The group to add this sound to.
	 * @param   autoDestroy    Whether to destroy this sound when it finishes playing.
	 *                         Leave this value set to "false" if you want to re-use this FlxSound instance.
	 * @param   onComplete     Called when the sound finished playing
	 * @return  A FlxSound object.
	 */
	public function play(embeddedSound:FlxSoundAsset, volume = 1.0, looped = false, ?group:FlxSoundGroup, autoDestroy = true, ?onComplete:Void->Void):FlxSound
	{
		var sound = list.recycle(FlxSound).loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);
		return loadHelper(sound, volume, group, true);
	}

	/**
	 * Plays a sound from a URL. Tries to recycle a cached sound first.
	 * NOTE: Just calls FlxG.sound.load() with AutoPlay == true.
	 *
	 * @param   url          Load a sound from an external web resource instead.
	 * @param   volume       How loud to play it (0 to 1).
	 * @param   looped       Whether to loop this sound.
	 * @param   group        The group to add this sound to.
	 * @param   autoDestroy  Whether to destroy this sound when it finishes playing.
	 *                       Leave this value set to "false" if you want to re-use this FlxSound instance.
	 * @param   onComplete   Called when the sound finished playing
	 * @param   onLoad       Called when the sound finished loading.
	 * @return  A FlxSound object.
	 */
	public function stream(url:String, volume = 1.0, looped = false, ?group:FlxSoundGroup, autoDestroy = true, ?onComplete:Void->Void,
			?onLoad:Void->Void):FlxSound
	{
		return load(null, volume, looped, group, autoDestroy, true, url, onComplete, onLoad);
	}

	/**
	 * Pauses every audios that are listed that are about to and currently playing.
	 */
	public function pause():Void
	{
		if (music != null && music.exists)
		{
			if (music._pausedPlay = music.source.playing) music.source.pause();
			music._pausedByHandler = true;
		}

		for (sound in list.members)
		{
			if (sound != null && sound.exists)
			{
				if (sound._pausedPlay = sound.source.playing) sound.source.pause();
				sound._pausedByHandler = true;
			}
		}

		paused = true;
	}

	/**
	 * Resumes back every audios that was playing and plays the pending audios.
	 */
	public function resume():Void
	{
		if (music != null && music.exists && music._pausedByHandler)
		{
			music._pausedByHandler = false;
			if (music._pausedPlay) music.source.play();
			music._pausedPlay = false;
		}

		for (sound in list.members)
		{
			if (sound != null && sound.exists && sound._pausedByHandler)
			{
				sound._pausedByHandler = false;
				if (sound._pausedPlay) sound.source.play();
				sound._pausedPlay = false;
			}
		}

		paused = false;
	}

	/**
	 * Called by FlxGame on state changes to stop and destroy sounds.
	 *
	 * @param   forceDestroy  Kill sounds even if persist is true.
	 */
	public function destroy(forceDestroy = false):Void
	{
		if (music != null && (forceDestroy || !music.persist))
		{
			music.destroy();
			music = null;
		}

		// Effectively removing null sounds and removing destroyed sounds if it exceed max pool count.
		var i = list.members.length, n = 0, sound:FlxSound;
		while (i-- > 0)
		{
			sound = list.members[i];
			if (sound == null)
			{
				FlxArrayUtil.swapAndPop(list.members, i);
			}
			else if (forceDestroy || !sound.persist)
			{
				if (n < poolMaxSounds) n++;
				else FlxArrayUtil.swapAndPop(list.members, i);
				sound.destroy();
			}
			else
			{
				n++;
			}
		}

		// bypass the null set accessor.
		Reflect.setField(list.members, "length", n);
	}

	/**
	 * Check the local sound data cache to see if a sound data with this key has been loaded already.
	 * 
	 * @param	key		The key identifying the sound data.
	 * @return	Whether or not this file can be found in the cache.
	 * 
	 * @since FunkinCrew's Flixel
	 */
	public inline function checkCache(key:String):Bool
	{
		return getCache(key) != null;
	}

	/**
	 * Removes and destroys a cached `FlxSoundData` from memory with specified key.
	 * @param	key			Key of the cached sound data.
	 * @param	destroy 	Should it automatically destroys it after removing (Default is `true`).
	 * 
	 * @since FunkinCrew's Flixel
	 */
	public function removeCache(key:String, destroy = true):Void
	{
		if (key == null) return;

		if (destroy)
		{
			var obj = getCache(key);
			if (obj != null) obj.destroy();
		}

		Assets.cache.removeSound(key);
		_cache.remove(key);
	}

	/**
	 * Caches the specified sound data.
	 * 
	 * @param	soundData	The sound data to cache.
	 * @return	The cached sound data.
	 * 
	 * @since FunkinCrew's Flixel
	 */
	public inline function addCache(soundData:FlxSoundData):FlxSoundData
	{
		if (soundData != null && (soundData.key is String)) _cache.set(soundData.key, soundData);
		return soundData;
	}

	/**
	 * Gets a cached `FlxSoundData` with specified key.
	 * @param	key		Key of the cached sound data.
	 * @return	The `FlxSoundData` with the specified key, or null if the object doesn't exist.
	 * 
	 * @since FunkinCrew's Flixel
	 */
	public inline function getCache(key:String):FlxSoundData
	{
		return _cache.get(key);
	}

	/**
	 * Clears audio data cache (and destroys those auio datas).
	 * `FlxSoundData` object will be removed and destroyed only if it shouldn't persist in the cache and its useCount is 0.
	 * 
	 * @since FunkinCrew's Flixel
	 */
	public function clearCache():Void
	{
		if (_cache == null)
		{
			_cache = new Map();
			return;
		}

		for (key in _cache.keys())
		{
			var obj = _cache.get(key);
			if (obj.unused)
			{
				Assets.cache.removeSound(key);
				_cache.remove(key);
				obj.destroy();
			}
			else if (obj != null && !obj.persist && obj.useCount <= 0)
			{
				obj.unused = true;
			}
		}
	}

	/**
	 * Completely resets audio data cache, which means destroying ALL of the cached FlxSoundData objects.
	 * 
	 * @since FunkinCrew's Flixel
	 */
	public function resetCache():Void
	{
		if (_cache == null)
		{
			_cache = new Map();
			return;
		}

		for (key in _cache.keys()) removeCache(key);
	}

	/**
	 * Removes all unused sound datas from cache,
	 * but skips somes which should persist in cache and shouldn't be destroyed on no use.
	 * 
	 * @since FunkinCrew's Flixel
	 */
	public function clearUnused():Void
	{
		for (key in _cache.keys())
		{
			var obj = _cache.get(key);
			if (obj != null && obj.useCount <= 0 && !obj.persist && obj.destroyOnNoUse)
			{
				Assets.cache.removeSound(key);
				_cache.remove(key);
				obj.destroy();
			}
		}
	}

	/**
	 * Gets a key from a cached AudioBuffer.
	 *
	 * @param	buffer	AudioBuffer to find in the cache.
	 * @return	The AudioBuffer's key or null if there isn't such AudioBuffer in cache.
	 * 
	 * @since FunkinCrew's Flixel
	 */
	public function findKeyForBuffer(buffer:AudioBuffer):Null<String>
	{
		for (key in _cache.keys())
		{
			var obj = _cache.get(key);
			if (obj != null && obj.buffer == buffer) return key;
		}
		return null;
	}

	/**
	 * Toggles muted, also activating the sound tray.
	 */
	public function toggleMuted():Void
	{
		muted = !muted;
		showSoundTray(true);
	}

	/**
	 * Changes the volume by a certain amount, also activating the sound tray.
	 */
	public function changeVolume(value:Float):Void
	{
		volume += value;
		muted = false;
		showSoundTray(value > 0);
	}

	public function linearToLog(x:Float, minValue:Float = 0.001):Float
	{
		// If linear volume is 0, return 0
		if (x <= 0) return 0;

		// Ensure x is between 0 and 1
		x = Math.min(1, x);

		// Convert linear scale to logarithmic
		return Math.exp(Math.log(minValue) * (1 - x));
	}

	public function logToLinear(x:Float, minValue:Float = 0.001):Float
	{
		// If logarithmic volume is below than minValue, return 0
		if (x <= minValue) return 0;

		// Ensure x is between minValue and 1
		x = Math.min(1, x);

		// Convert logarithmic scale to linear
		return 1 - (Math.log(Math.max(x, minValue)) / Math.log(minValue));
	}

	/**
	 * Shows the sound tray if it is enabled.
	 * @param up Whether or not the volume is increasing.
	 */
	public function showSoundTray(up:Bool = false):Void
	{
		#if FLX_SOUND_TRAY
		if (FlxG.game.soundTray != null && soundTrayEnabled)
		{
			if (up)
				FlxG.game.soundTray.showIncrement();
			else
				FlxG.game.soundTray.showDecrement();
		}
		#end
	}
	
	/**
	 * Takes the volume scale used by Flixel fields and gives the final transformed volume that is
	 * actually used to play the sound. To reverse this operation, use `reverseSoundCurve`. This
	 * field is `dynamic` and can be overwritten. 
	 */
	public dynamic function applySoundCurve(volume:Float)
	{
		return Math.pow(volume, 1.75);
		
		// Example of linear to logarithmic sound curve:
		// final clampedVolume = Math.max(0, Math.min(1, volume));
		// return Math.exp(Math.log(0.001) * (1 - clampedVolume));
	}
	
	/**
	 * Takes a transformed volume and returns the corresponding volume scale used by Flixel fields.
	 * Used to reverse the operation of `applySoundCurve`. This field is `dynamic` and can be
	 * set to a custom function.
	 */
	public dynamic function reverseSoundCurve(curvedVolume:Float)
	{
		return Math.pow(curvedVolume, 0.5714285714285714);
		
		// Example of logarithmic to linear sound curve:
		// final clampedVolume = Math.max(minValue, Math.min(1, x));
		// return 1 - (Math.log(clampedVolume) / Math.log(0.001));
	}
	
	function new()
	{
		resetCache();

		AudioManager.onDefaultPlaybackDeviceChanged.add(onDefaultDeviceChanged.dispatch);
		AudioManager.onPlaybackDeviceAdded.add(onDeviceAdded.dispatch);
		AudioManager.onPlaybackDeviceRemoved.add(onDeviceRemoved.dispatch);
		#if FLX_SAVE
		loadSavedPrefs();
		#end
	}

	/**
	 * Called by the game loop to make sure the sounds get updated each frame.
	 */
	@:allow(flixel.FlxGame)
	function update(elapsed:Float):Void
	{
		#if FLX_KEYBOARD
		if (keysAllowed && !FlxInputText.globalManager.isTyping)
		{
			if (FlxG.keys.anyJustReleased(muteKeys))
				toggleMuted();
			else if (FlxG.keys.anyJustReleased(volumeUpKeys))
				changeVolume(0.1);
			else if (FlxG.keys.anyJustReleased(volumeDownKeys))
				changeVolume(-0.1);
		}
		#end

		if (!paused)
		{
			if (_lastTimeScale != FlxG.timeScale)
			{
				_lastTimeScale = FlxG.timeScale;
				if (music != null && music.active) music._updatePitch();
				for (sound in list.members)
				{
					if (sound != null && sound.active) sound._updatePitch();
				}
			}

			if (music != null && music.active) music.update(elapsed);
			if (list != null && list.active) list.update(elapsed);
		}
	}

	@:allow(flixel.FlxGame)
	function onFocusLost():Void
	{
		if (_lostFocusPause = canAutoPause && FlxG.autoPause && !paused)
		{
			pause();
		}
	}

	@:allow(flixel.FlxGame)
	function onFocus():Void
	{
		if (_lostFocusPause)
		{
			_lostFocusPause = false;
			resume();
		}
	}

	#if FLX_SAVE
	/**
	 * Loads saved sound preferences if they exist.
	 */
	function loadSavedPrefs():Void
	{
		if (!save.isBound)
			return;

		if (save.data.volume != null)
		{
			set_volume(save.data.volume);
		}

		if (save.data.mute != null)
		{
			set_muted(save.data.mute);
		}
	}
	#end

	function updateVolume():Void
	{
		if (music != null && music.exists)
		{
			music._updateVolume();
		}

		for (sound in list.members)
		{
			if (sound != null && sound.exists)
			{
				sound._updateVolume();
			}
		}
	}

	inline function get_automaticDefaultDevice():Bool
	{
		return AudioManager.automaticDefaultPlaybackDevice;
	}

	function set_automaticDefaultDevice(value:Bool):Bool
	{
		if (AudioManager.automaticDefaultPlaybackDevice != value)
		{
			AudioManager.automaticDefaultPlaybackDevice = value;
			if (value && AudioManager.getCurrentPlaybackDeviceName() != AudioManager.getPlaybackDefaultDeviceName())
			{
				AudioManager.refresh();
			}
		}
		return value;
	}

	inline function get_deviceName():String
	{
		return AudioManager.getCurrentPlaybackDeviceName();
	}

	function set_deviceName(value:String):String
	{
		if (AudioManager.getCurrentPlaybackDeviceName() != value)
		{
			if (AudioManager.refresh(value)) return value;
			else
			{
				AudioManager.refresh();
				return AudioManager.getCurrentPlaybackDeviceName();
			}
		}
		else
		{
			return value;
		}
	}

	function get_volume():Float
	{
		return _volume;
	}

	function set_volume(value:Float):Float
	{
		var prevVolume = _volume;
		_volume = FlxMath.bound(value, 0, 1);

		// https://github.com/FunkinCrew/flixel/pull/12
		#if !mobile
		// Initially for the audio overhaul changes generally, it was made to use the global volume in AudioManager,
		//  instead of iterating every FlxSounds, but ensues an issues where sounds outside flixel (openfl, lime, hxvlc)
		//  are affected too, so this was reverted. -raltyro
		/*
		if (AudioManager.muted)
		{
			AudioManager.gain = 0;
		}
		else
		{
			AudioManager.gain = applySoundCurve(value);
			if (value != _volume)
			{
				if (volumeHandler != null) volumeHandler(value);
				onVolumeChange.dispatch(value);
			}
		}
		*/

		if (!_muted && _volume != prevVolume)
		{
			updateVolume();

			if (volumeHandler != null) volumeHandler(value);
			onVolumeChange.dispatch(value);
		}
		#end

		return _volume;
	}

	function get_muted():Bool
	{
		return _muted;
	}

	function set_muted(value:Bool):Bool
	{
		// https://github.com/FunkinCrew/flixel/pull/12
		#if mobile
		return _muted = value;
		#else
		if (_muted != value)
		{
			_muted = value;
			updateVolume();

			var volume = value ? 0 : _volume;
			if (volumeHandler != null) volumeHandler(volume);
			onVolumeChange.dispatch(volume);
		}

		return value;
		#end
	}
}
#end
