package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.FlxBasic;

/*
 * This is here to help our shader debug stuff work by always call its update()
*/
class ShaderUpdater extends FlxBasic {
	var shader:PixelateShader;

	public function new() {
		super();
	}

	public function setShader(s:PixelateShader) {
		shader = s;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (shader != null) {
			shader.update(elapsed);
		}
	}
}