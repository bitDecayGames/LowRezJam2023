package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.FlxBasic;

/*
 * This is here to help our shader debug stuff work by always call its update()
*/
class ShaderUpdater extends FlxBasic {
	var shader:PixelateShader;

	public function new(shader:PixelateShader) {
		super();
		this.shader = shader;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		shader.update(elapsed);
	}
}