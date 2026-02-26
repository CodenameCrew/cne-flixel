package flixel.system.frontEnds;

import openfl.geom.Rectangle;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSignal.FlxTypedSignal;

using flixel.util.FlxArrayUtil;

/**
 * Accessed via `FlxG.cameras`.
 */
class CameraFrontEnd
{
	/**
	 * An array listing FlxCamera objects that are used to draw stuff.
	 * By default flixel creates one camera the size of the screen.
	 * Do not edit directly, use `add` and `remove` instead.
	 */
	public var list(default, null):Array<FlxCamera> = [];

	/**
		* Array listing all cameras marked as default draw targets, `FlxBasics` with no
		*`cameras` set will render to them.
	 */
	var defaults:Array<FlxCamera> = [];

	/**
	 * The current (global, applies to all cameras) bgColor.
	 */
	public var bgColor(get, set):FlxColor;

	/** @since 4.2.0 */
	public var cameraAdded(default, null):FlxTypedSignal<FlxCamera->Void> = new FlxTypedSignal<FlxCamera->Void>();

	/** @since 4.2.0 */
	public var cameraRemoved(default, null):FlxTypedSignal<FlxCamera->Void> = new FlxTypedSignal<FlxCamera->Void>();

	/**
	 * Codename Engine only!!
	 * @since 5.3.0
	 */
	public var preCameraResized(default, null):FlxTypedSignal<FlxCamera->Void> = new FlxTypedSignal<FlxCamera->Void>();

	/** @since 4.2.0 */
	public var cameraResized(default, null):FlxTypedSignal<FlxCamera->Void> = new FlxTypedSignal<FlxCamera->Void>();

	/**
	 * Allows you to possibly slightly optimize the rendering process IF
	 * you are not doing any pre-processing in your game state's draw() call.
	 */
	public var useBufferLocking:Bool = false;

	/**
	 * Internal helper variable for clearing the cameras each frame.
	 */
	var _cameraRect:Rectangle = new Rectangle();

	/**
	 * Add a new camera object to the game.
	 * Handy for PiP, split-screen, etc.
	 * @see flixel.FlxBasic.cameras
	 *
	 * @param	NewCamera         The camera you want to add.
	 * @param	DefaultDrawTarget Whether to add the camera to the list of default draw targets. If false,
	 *                            `FlxBasics` will not render to it unless you add it to their `cameras` list.
	 * @return	This FlxCamera instance.
	 */
	public function add<T:FlxCamera>(NewCamera:T, DefaultDrawTarget:Bool = true):T
	{
		FlxG.game.addChildAt(NewCamera.flashSprite, FlxG.game.getChildIndex(FlxG.game._inputContainer));

		list.push(NewCamera);
		if (DefaultDrawTarget)
			defaults.push(NewCamera);

		NewCamera.ID = list.length - 1;
		cameraAdded.dispatch(NewCamera);
		return NewCamera;
	}

	/**
	 * Inserts a new camera object to the game.
	 *
	 * - If `position` is negative, `list.length + position` is used
	 * - If `position` exceeds `list.length`, the camera is added to the end.
	 *
	 * @param	NewCamera         The camera you want to add.
	 * @param	Position          The position in the list where you want to insert the camera
	 * @param	DefaultDrawTarget Whether to add the camera to the list of default draw targets. If false,
	 *                            `FlxBasics` will not render to it unless you add it to their `cameras` list.
	 * @return	This FlxCamera instance.
	 */
	public function insert<T:FlxCamera>(NewCamera:T, Position:Int, DefaultDrawTarget:Bool = true):T
	{
		// negative numbers are relative to the length (match Array.insert's behavior)
		if (Position < 0)
			Position += list.length;

		// invalid ranges are added (match Array.insert's behavior)
		if (Position >= list.length)
			return add(NewCamera);

		final childIndex = FlxG.game.getChildIndex(list[Position].flashSprite);
		FlxG.game.addChildAt(NewCamera.flashSprite, childIndex);

		list.insert(Position, NewCamera);
		if (DefaultDrawTarget)
			defaults.push(NewCamera);

		for (i in Position...list.length)
			list[i].ID = i;

		cameraAdded.dispatch(NewCamera);
		return NewCamera;
	}

	/**
	 * Remove a camera from the game.
	 *
	 * @param   Camera    The camera you want to remove.
	 * @param   Destroy   Whether to call destroy() on the camera, default value is true.
	 */
	public function remove(Camera:FlxCamera, Destroy:Bool = true):Void
	{
		var index:Int = list.indexOf(Camera);
		if (index == -1 || Camera == null)
		{
			FlxG.log.warn("FlxG.cameras.remove(): The camera you attempted to remove is not a part of the game.");
			return;
		}
		removeAt(index, Destroy);
	}

	/**
	 * Set the order of the cameras.
	 *
	 * @param   order     The order of the cameras.
	 * @param   defaults  The default draw targets. (If null, the first camera will be used as default.)
	 * @param   destroy   Whether to destroy the removed cameras. Default value is false.
	**/
	public function setOrder(Order:Array<FlxCamera>, ?Defaults:Null<Array<FlxCamera>>, ?Destroy:Bool = false):Void
	{
		for (camera in list)
		{
			FlxG.game.removeChild(camera.flashSprite);

			if (!Order.contains(camera))
			{
				if (Destroy)
					camera.destroy();
				cameraRemoved.dispatch(camera);
			}
		}
		var oldList = this.list.copy();
		this.list.splice(0, this.list.length); // clear but keep references
		this.defaults.splice(0, this.defaults.length);

		for (i => camera in Order)
		{
			if (camera == null)
			{
				FlxG.log.warn('FlxG.cameras.setOrder(): Camera at index $i is null.');
				continue;
			}
			FlxG.game.addChildAt(camera.flashSprite, FlxG.game.getChildIndex(FlxG.game._inputContainer));
			camera.ID = list.length;
			list.push(camera);
			if (!oldList.contains(camera))
				cameraAdded.dispatch(camera);
		}

		if (Defaults == null && list.length > 0)
			Defaults = [list[0]];

		if (Defaults != null)
			for (camera in Defaults)
			{
				if (camera == null)
					continue;
				if (list.contains(camera))
					this.defaults.push(camera);
			}
	}

	/**
	 * Remove a camera from the game.
	 *
	 * @param   Index     The index of the camera you want to remove.
	 * @param   Destroy   Whether to call destroy() on the camera, default value is true.
	 */
	public function removeAt(Index:Int, Destroy:Bool = true):Void
	{
		if (Index < 0 || Index >= list.length)
		{
			FlxG.log.warn("FlxG.cameras.removeAt(): The camera you attempted to remove is not a part of the game.");
			return;
		}

		var camera = list[Index];

		FlxG.game.removeChild(camera.flashSprite);
		list.splice(Index, 1);
		defaults.remove(camera);

		if (FlxG.renderTile)
		{
			for (i in 0...list.length)
			{
				list[i].ID = i;
			}
		}

		if (Destroy)
			camera.destroy();

		cameraRemoved.dispatch(camera);
	}

	/**
	 * Returns the index of the specified camera in the list.
	 *
	 * @param   Camera    The camera you want to find the index of.
	 * @return  The index of the camera in the list.
	**/
	public inline function indexOf(Camera:FlxCamera):Int
	{
		return list.indexOf(Camera);
	}

	/**
	 * Returns true if the specified camera is in the list.
	 *
	 * @param   Camera    The camera you want to check for.
	 * @return  True if the camera is in the list.
	**/
	public inline function contains(Camera:FlxCamera):Bool
	{
		return list.contains(Camera);
	}

	/**
	 * If set to true, the camera is listed as a default draw target, meaning `FlxBasics`
	 * render to the specified camera if the `FlxBasic` has a null `cameras` value.
	 * @see flixel.FlxBasic.cameras
	 *
	 * @param camera The camera you wish to change.
	 * @param value  If false, FlxBasics will not render to it unless you add it to their `cameras` list.
	 * @since 4.9.0
	 */
	public function setDefaultDrawTarget(camera:FlxCamera, value:Bool)
	{
		if (!list.contains(camera))
		{
			FlxG.log.warn("FlxG.cameras.setDefaultDrawTarget(): The specified camera is not a part of the game.");
			return;
		}

		var index = defaults.indexOf(camera);

		if (value && index == -1)
			defaults.push(camera);
		else if (!value)
			defaults.splice(index, 1);
	}

	/**
	 * Dumps all the current cameras and resets to just one camera.
	 * Handy for doing split-screen especially.
	 *
	 * @param	NewCamera	Optional; specify a specific camera object to be the new main camera.
	 */
	public function reset(?NewCamera:FlxCamera):Void
	{
		while (list.length > 0)
			remove(list[0]);

		if (NewCamera == null)
			NewCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);

		FlxG.camera = add(NewCamera);
		NewCamera.ID = 0;

		FlxCamera._defaultCameras = defaults;
	}

	/**
	 * All screens are filled with this color and gradually return to normal.
	 *
	 * @param	Color		The color you want to use.
	 * @param	Duration	How long it takes for the flash to fade.
	 * @param	OnComplete	A function you want to run when the flash finishes.
	 * @param	Force		Force the effect to reset.
	 */
	public function flash(Color:FlxColor = FlxColor.WHITE, Duration:Float = 1, ?OnComplete:Void->Void, Force:Bool = false):Void
	{
		for (camera in list)
		{
			camera.flash(Color, Duration, OnComplete, Force);
		}
	}

	/**
	 * The screen is gradually filled with this color.
	 *
	 * @param	Color		The color you want to use.
	 * @param	Duration	How long it takes for the fade to finish.
	 * @param 	FadeIn 		True fades from a color, false fades to it.
	 * @param	OnComplete	A function you want to run when the fade finishes.
	 * @param	Force		Force the effect to reset.
	 */
	public function fade(Color:FlxColor = FlxColor.BLACK, Duration:Float = 1, FadeIn:Bool = false, ?OnComplete:Void->Void, Force:Bool = false):Void
	{
		for (camera in list)
		{
			camera.fade(Color, Duration, FadeIn, OnComplete, Force);
		}
	}

	/**
	 * A simple screen-shake effect.
	 *
	 * @param	Intensity	Percentage of screen size representing the maximum distance that the screen can move while shaking.
	 * @param	Duration	The length in seconds that the shaking effect should last.
	 * @param	OnComplete	A function you want to run when the shake effect finishes.
	 * @param	Force		Force the effect to reset (default = true, unlike flash() and fade()!).
	 * @param	Axes		On what axes to shake. Default value is XY / both.
	 */
	public function shake(Intensity:Float = 0.05, Duration:Float = 0.5, ?OnComplete:Void->Void, Force:Bool = true, ?Axes:FlxAxes):Void
	{
		for (camera in list)
		{
			camera.shake(Intensity, Duration, OnComplete, Force, Axes);
		}
	}

	@:allow(flixel.FlxG)
	function new()
	{
		FlxCamera._defaultCameras = defaults;
	}

	/**
	 * Called by the game object to lock all the camera buffers and clear them for the next draw pass.
	 */
	@:allow(flixel.FlxGame)
	inline function lock():Void
	{
		for (camera in list)
		{
			if (camera == null || !camera.exists || !camera.visible)
			{
				continue;
			}

			if (FlxG.renderBlit)
			{
				camera.checkResize();

				if (useBufferLocking)
				{
					camera.buffer.lock();
				}
			}

			if (FlxG.renderTile)
			{
				camera.clearDrawStack();
				camera.canvas.graphics.clear();
				// Clearing camera's debug sprite
				#if FLX_DEBUG
				camera.debugLayer.graphics.clear();
				#end
			}

			if (FlxG.renderBlit)
			{
				camera.fill(camera.bgColor, camera.useBgAlphaBlending);
				camera.screen.dirty = true;
			}
			else
			{
				camera.fill(camera.bgColor.to24Bit(), camera.useBgAlphaBlending, camera.bgColor.alphaFloat);
			}
		}
	}

	@:allow(flixel.FlxGame)
	inline function render():Void
	{
		if (FlxG.renderTile)
		{
			for (camera in list)
			{
				if ((camera != null) && camera.exists && camera.visible)
				{
					camera.render();
				}
			}
		}
	}

	/**
	 * Called by the game object to draw the special FX and unlock all the camera buffers.
	 */
	@:allow(flixel.FlxGame)
	inline function unlock():Void
	{
		for (camera in list)
		{
			if ((camera == null) || !camera.exists || !camera.visible)
			{
				continue;
			}

			camera.drawFX();

			if (FlxG.renderBlit)
			{
				if (useBufferLocking)
				{
					camera.buffer.unlock();
				}

				camera.screen.dirty = true;
			}
		}
	}

	/**
	 * Called by the game object to update the cameras and their tracking/special effects logic.
	 */
	@:allow(flixel.FlxGame)
	inline function update(elapsed:Float):Void
	{
		for (camera in list)
		{
			if (camera != null && camera.exists && camera.active)
			{
				camera.update(elapsed);
			}
		}
	}

	/**
	 * Resizes and moves cameras when the game resizes (onResize signal).
	 */
	@:allow(flixel.FlxGame)
	function resize():Void
	{
		for (camera in list)
		{
			camera.onResize();
		}
	}

	function get_bgColor():FlxColor
	{
		return (FlxG.camera == null) ? FlxColor.BLACK : FlxG.camera.bgColor;
	}

	function set_bgColor(Color:FlxColor):FlxColor
	{
		for (camera in list)
		{
			camera.bgColor = Color;
		}

		return Color;
	}
}
