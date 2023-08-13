package entities.particles;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.particles.FlxEmitter;
import collision.Color;
import flixel.effects.particles.FlxParticle;

class UpgradeParticle extends FlxEmitter {
	var lastImpactAngle = Math.POSITIVE_INFINITY;

	public function new(X:Float, Y:Float, c:Color) {
		super(X, Y + 4);
		loadParticles(AssetPaths.simple_round__png);
		color.set(c.toFlxColor());
		lifespan.set(.3, .3);
		scale.set(1.5, 1.5, .1, .1);
		// alpha.set(.5, 1, .1, .2);
		speed.set(30);
		start(false, .05);
		FlxTween.tween(this, {y: y - 16}, .9, {
			ease: FlxEase.sineInOut,
			type: FlxTweenType.PINGPONG,
		});
	}
}