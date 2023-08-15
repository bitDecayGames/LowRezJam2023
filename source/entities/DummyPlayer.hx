package entities;

import collision.ColorCollideSprite;
import flixel.effects.particles.FlxEmitter;
import entities.particles.DeathParticles;
import loaders.Aseprite;
import loaders.AsepriteMacros;
import flixel.FlxSprite;

using bitdecay.flixel.extensions.FlxObjectExt;

class DummyPlayer extends ColorCollideSprite {
	private static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/player.json");

	public var emitterCB:Array<FlxEmitter>->Void = null;

	public function new(centerX:Float, centerY:Float) {
		super(centerX, centerY, EMPTY);

		Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		animation.play(anims.powerup);
		animation.finishCallback = finished;

		animation.callback = (name, frameNumber, frameIndex) -> {
			if (name == anims.run) {
				if (frameNumber == 4 || frameNumber == 10)  {
					FmodManager.PlaySoundOneShot(FmodSFX.PlayerStep);
				}
			}
		}

		this.setPositionMidpoint(centerX, centerY);
	}

	public function jump() {
		animation.play(anims.jump);
		FmodManager.PlaySoundOneShot(FmodSFX.PlayerJump4);
	}

	public function fall() {
		animation.play(anims.fall);
	}
	
	public function land() {
		animation.play(anims.stand);
		FmodManager.PlaySoundOneShot(FmodSFX.PlayerLand1);
	}

	public function crouch() {
		animation.play(anims.crouch);
		FmodManager.PlaySoundOneShot(FmodSFX.PlayerDuck2);
	}

	public function uncrouch() {
		animation.play(anims.stand);
		FmodManager.PlaySoundOneShot(FmodSFX.PlayerUnduck2);
	}

	public function jumpCrouch() {
		animation.play(anims.jumpCrouch);
		FmodManager.PlaySoundOneShot(FmodSFX.PlayerDuck2);
	}

	public function unJumpCrouch() {
		animation.play(anims.fall);
		FmodManager.PlaySoundOneShot(FmodSFX.PlayerUnduck2);
	}

	public function explode() {
		animation.play(anims.death);
	}

	public function run() {
		animation.play(anims.run);
		animation.getByName(anims.run).frameRate = 30;
	}

	public function stopRun() {
		FmodManager.PlaySoundOneShot(FmodSFX.PlayerSkidShort);
		animation.play(anims.skid);
	}

	public function stand() {
		animation.play(anims.stand);
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