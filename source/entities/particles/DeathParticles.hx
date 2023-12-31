package entities.particles;

import flixel.util.FlxColor;
import collision.Color;
import states.PlayState;
import flixel.effects.particles.FlxEmitter;

class DeathParticles {

	public static function create(pX:Float, pY:Float, circular:Bool, colors:Array<Color>):Array<FlxEmitter> {
		var e = new Array<FlxEmitter>();
		for (c in colors) {
			e.push(createPoofOfColor(pX, pY, circular, c));
		}
		return e;
	}

	public static function createPoofOfColor(pX:Float, pY:Float, circle:Bool, color:Color):FlxEmitter {
		var emitter = new FlxEmitter(pX, pY);
		emitter.loadParticles(AssetPaths.simple_round__png);
		emitter.color.set(cast color, cast color);
		emitter.lifespan.set(1.25, 2.5);
		emitter.scale.set(.8, .8, 1.5, 1.5, .1, .1, .5, .5);
		emitter.alpha.set(.1, 1, 0, 0);
		emitter.acceleration.set(0, 10, 0, 20, 0, -70, 0, -120);
		emitter.angularVelocity.set(100, 1000);
		emitter.speed.set(20, 300);
		emitter.drag.set(80, 20, 600, 30);
		if (circle) {
			emitter.launchAngle.set(0, 359);
		} else {
			emitter.launchAngle.set(-200, 20);
		}
		emitter.start(true);

		PlayState.ME.addParticle(emitter, true);
		return emitter;
	}
	
}