package flixel.system.debug.console;

class ConsoleHistory
{
	static inline var MAX_LENGTH:Int = 50;

	public var commands:Array<String>;

	public var isEmpty(get, never):Bool;

	var index:Int = 0;

	public function new()
	{
		var save = FlxDebugger.save;
		if (save.isBound)
		{
			if (save.data.history != null)
			{
				commands = save.data.history;
				index = commands.length;
			}
			else
			{
				commands = [];
				save.data.history = commands;
			}
		}
		else
		{
			commands = [];
		}
	}

	public function getPreviousCommand():String
	{
		if (index > 0)
			index--;
		return commands[index];
	}

	public function getNextCommand():String
	{
		if (index < commands.length)
			index++;
		return (commands[index] != null) ? commands[index] : "";
	}

	public function addCommand(command:String)
	{
		// Only save new commands
		if (isEmpty || getPreviousCommand() != command)
		{
			commands.push(command);
			if (FlxDebugger.save.isBound)
				FlxDebugger.save.flush();

			if (commands.length > MAX_LENGTH)
				commands.shift();
		}

		index = commands.length;
	}

	public function clear()
	{
		commands.splice(0, commands.length);
		FlxDebugger.save.flush();
	}

	function get_isEmpty():Bool
	{
		return commands.length == 0;
	}
}
