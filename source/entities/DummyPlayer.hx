package entities;

import flixel.effects.particles.FlxEmitter;
import entities.particles.DeathParticles;
import loaders.Aseprite;
import loaders.AsepriteMacros;
import flixel.FlxSprite;

using bitdecay.flixel.extensions.FlxObjectExt;

class DummyPlayer extends FlxSprite {
	private static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/player.json");

	public var emitterCB:Array<FlxEmitter>->Void = null;

	public function new(centerX:Float, centerY:Float) {
		super(centerX, centerY);

		Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		animation.play(anims.powerup);
		animation.finishCallback = finished;

		this.setPositionMidpoint(centerX, centerY);
	}

	public function explode() {
		animation.play(anims.death);
	}

	function finished(name:String) {
		if (name == anims.death) {
			FmodManager.PlaySoundOneShot(FmodSFX.PlayerDieBurst2);

			var midpoint = getGraphicMidpoint();
			var emitters = DeathParticles.create(midpoint.x, midpoint.y, true, [ALL, ALL, ALL, ALL, ALL]);
			if (emitterCB != null) {
				emitterCB(emitters);
			}
			kill();
		}
	}
}