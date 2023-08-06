package entities.particles;

import collision.Color;
import states.PlayState;
import flixel.effects.particles.FlxEmitter;

class DeathParticles {

	public static function create(pX:Float, pY:Float, colors:Array<Color>) {
		for (c in colors) {
			createPoofOfColor(pX, pY, c);
		}
	}

	public static function createPoofOfColor(pX:Float, pY:Float, color:Color) {
		var emitter = new FlxEmitter(pX, pY);
		emitter.loadParticles(AssetPaths.simple_round__png);
		emitter.color.set(cast color);
		emitter.lifespan.set(1, 3);
		emitter.scale.set(.1, .1, .5, .5, .8, .8, 1, 1);
		emitter.alpha.set(.1, 1, 0, 0);
		emitter.acceleration.set(0, 10, 0, 20, 0, -70, 0, -120);
		emitter.speed.set(20, 300);
		emitter.drag.set(80, 20, 600, 30);
		emitter.launchAngle.set(-200, 20);
		emitter.start(true);
		// emitter.emitting = false;

		PlayState.ME.addParticle(emitter);
	}
	
}