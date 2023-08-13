package entities.enemy;

import echo.Body;
import flixel.math.FlxPoint;
import entities.enemy.BaseLaser.BaseLaserOptions;
import loaders.Aseprite;
import loaders.AsepriteMacros;

class LaserStationary extends BaseLaser {
	private static var anims = AsepriteMacros.tagNames("assets/aseprite/stationaryTurret.json");

	public function new(options:BaseLaserOptions) {
		super(options);
		cooldown -= options.delay;
	}

	override function configSprite() {
		Aseprite.loadAllAnimations(this, AssetPaths.stationaryTurret__json);
		animation.frameIndex = 0;
	}

	override function cooldownEnd() {
		super.cooldownEnd();
		chargeSoundId = FmodManager.PlaySoundWithReference(FmodSFX.LaserStationaryCharge);
		trace("Charge sound set to " + chargeSoundId);
	}

	override function laserFired() {
		super.laserFired();
		blastSoundId = FmodManager.PlaySoundWithReference(FmodSFX.LaserStationaryBlast2);
		trace("Blast sound set to " + blastSoundId);
	}
}