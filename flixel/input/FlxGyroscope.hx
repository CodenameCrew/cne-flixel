package flixel.input;


#if FLX_GYROSCOPE
import openfl.events.DeviceRotationEvent;
import openfl.sensors.DeviceRotation;

/**
 * A class providing access to the accelerometer data of the device.
 */
class FlxGyroscope
{

	/**
	 * Represented as change in pitch per update.
	 * Meaning if your device was perfectly still, this value would
	 * be 0.
	 */
	public var pitch(default, null):Float = 0;

	/**
	 * Represented as change in roll per update.
	 * Meaning if your device was perfectly still, this value would
	 * be 0.
	 */
	public var roll(default, null):Float = 0;

	/**
	 * Represented as change in yaw per update.
	 * Meaning if your device was perfectly still, this value would
	 * be 0.
	 */
	public var yaw(default, null):Float = 0;

	/**
	 * Wether the gyroscope is supported on this device
	 */
	public var isSupported(get, never):Bool;

	var _sensor:DeviceRotation;

	public function new()
	{
		if (DeviceRotation.isSupported)
		{
			_sensor = new DeviceRotation();
			_sensor.addEventListener(DeviceRotationEvent.UPDATE, update);
		}
	}

	inline function get_isSupported():Bool
	{
		return DeviceRotation.isSupported;
	}

	function update(Event:DeviceRotationEvent):Void
	{
		// TODO: double check if these values are actually flipped
		// for android/js, I copy pasted this code from `FlxAccelerometer`!

		#if (android || js)
		pitch = Event.pitch;
		roll = Event.roll;
		yaw = Event.yaw;
		#else // Values on iOS and BlackBerry are inverted
		pitch = -Event.pitch;
		roll = -Event.roll;
		yaw = -Event.yaw;
		#end

		// TODO: Check if these divisions are needed on js
		#if js
		pitch /= 10;
		roll /= 10;
		yaw /= 10;
		#end
	}

	public function toString():String
	{
		return '$isSupported $pitch $yaw $roll';
	}
}
#end
