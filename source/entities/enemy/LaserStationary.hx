package entities.enemy;

import entities.enemy.BaseLaser.BaseLaserOptions;
import loaders.Aseprite;
import loaders.AsepriteMacros;

class LaserStationary extends BaseLaser {
	private static var anims = AsepriteMacros.tagNames("assets/aseprite/stationaryTurret.json");

	public function new(options:BaseLaserOptions) {
		super(options);
	}

	override function configSprite() {
		Aseprite.loadAllAnimations(this, AssetPaths.stationaryTurret__json);
		animation.frameIndex = 0;
	}

	override function cooldownEnd() {
		super.cooldownEnd();
		FmodManager.PlaySoundOneShot(FmodSFX.LaserStationaryCharge);
	}

	override function laserFired() {
		super.laserFired();
		FmodManager.PlaySoundOneShot(FmodSFX.LaserStationaryBlast);
	}
}