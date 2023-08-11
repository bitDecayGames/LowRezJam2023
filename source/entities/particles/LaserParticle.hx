package entities.particles;

import flixel.effects.particles.FlxEmitter;
import collision.Color;
import flixel.effects.particles.FlxParticle;

class LaserParticle extends FlxEmitter {
	var lastImpactAngle = Math.POSITIVE_INFINITY;

	public function new(X:Float, Y:Float, c:Color) {
		super(X, Y);
		loadParticles(AssetPaths.simple_round__png);
		color.set(c.toFlxColor());
		lifespan.set(.1, .4);
		scale.set(.8, .8, 1, 1, .1, .1, .5, .5);
		alpha.set(.5, 1, .1, .2);
		start(false, .05);
		emitting = false;
	}

	public function setImpactAngle(iAngle:Float) {
		if (iAngle != lastImpactAngle) {
			lastImpactAngle = iAngle;
			launchAngle.set(iAngle + 90, iAngle - 90);
		}
	}
}