package progress;

import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;
import flixel.FlxBasic;

/*
 * This is here to help time our gameplay consistently
*/
class PlayTimePlugin extends FlxBasic {
	public static var ME:PlayTimePlugin;

	public var accumulated:Float = 0.0;
	public var timerRunning:Bool = false;

	public function new() {
		super();
		ME = this;

		FlxG.signals.preStateSwitch.add(() -> {
			FlxG.watch.add(this, "accumulated", "Timer: ");
		});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (timerRunning) {
			accumulated += elapsed;
		}
	}
}