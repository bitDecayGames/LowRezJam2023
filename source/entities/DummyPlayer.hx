package entities;

import loaders.Aseprite;
import loaders.AsepriteMacros;
import flixel.FlxSprite;

using bitdecay.flixel.extensions.FlxObjectExt;

class DummyPlayer extends FlxSprite {
	private static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/player.json");


	public function new(centerX:Float, centerY:Float) {
		super(centerX, centerY);

		Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		animation.play(anims.powerup);
		animation.finishCallback = finished;

		this.setPositionMidpoint(centerX, centerY);
	}

	function finished(name:String) {
		// kill();
	}
}