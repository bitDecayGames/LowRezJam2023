package entities.particles;

import flixel.effects.particles.FlxEmitter;
import collision.Color;
import flixel.effects.particles.FlxParticle;

class LaserParticle extends FlxEmitter {
	public function new(X:Float, Y:Float, c:Color) {
		super(X, Y);
		loadParticles(AssetPaths.simple_round__png);
		color.set(c.toFlxColor());
		lifespan.set(.1, .25);
		scale.set(.1, .1, .5, .5, .8, .8, 1, 1);
		alpha.set(.1, 1, .1, 1);
		start(false, .05);
		emitting = false;
	}
}