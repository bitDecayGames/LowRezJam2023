package entities.enemy;

import bitdecay.flixel.spacial.Cardinal;
import entities.particles.LaserParticle;
import flixel.util.FlxTimer;
import collision.Collide;
import echo.FlxEcho;
import states.PlayState;
import echo.Line;
import flixel.FlxG;
import echo.math.Vector2;
import collision.Color;
import flixel.math.FlxPoint;
import flixel.effects.particles.FlxEmitter;
import collision.ColorCollideSprite;

using extension.CamExt;

typedef BaseLaserOptions = {
	spawnX: Float,
	spawnY: Float,
	dir: Cardinal,
	color: Color,
	rest: Float,
}

typedef LaserStationaryOptions = BaseLaserOptions & {
	laserTime: Float,
}

typedef LaserRailOptions = BaseLaserOptions & {
	path: Array<FlxPoint>,
}

class BaseLaser extends ColorCollideSprite {
	var tmp = FlxPoint.get();

	public var emitter:FlxEmitter;
	var emitterPoint = FlxPoint.get();

	var laserColor:Color;
	var laserAngle:Float;

	var COOLDOWN_TIME = 5.0;
	var cooldown = 0.0;
	var CHARGE_TIME = 1.5;
	var charging = 0.0;

	var LASER_TIME = 1.0;

	var maxDistanceToHear = 100;
	var volume = 1.0;
	var distanceFromCam = 0.0;
	var emitterDistanceFromCam = 0.0;

	var shooting = false;

	public function new(options:BaseLaserOptions) {
		super(options.spawnX, options.spawnY, EMPTY);

		laserColor = options.color;
		angle = options.dir + 180;
		laserAngle = options.dir + 270;

		COOLDOWN_TIME = options.rest;

		emitter = new LaserParticle(options.spawnX + emitterPoint.x, options.spawnY + emitterPoint.y, laserColor);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!shooting) {
			if (cooldown < COOLDOWN_TIME) {
				cooldown += elapsed;
				cooldownUpdate();

				if (cooldown >= COOLDOWN_TIME) {
					emitter.emitting = true;
					cooldownEnd();
				}

				emitterPoint.set(0, 8).pivotDegrees(FlxPoint.weak(), angle).add(x + width/2, y + height/2);
				emitter.setPosition(emitterPoint.x, emitterPoint.y);
			} else {
				charging += elapsed;

				chargeUpdate();
				
				if (charging >= CHARGE_TIME) {
					var laserLength:Float = FlxG.width;
					var laserCast = Line.get_from_vector(new Vector2(emitterPoint.x, emitterPoint.y), laserAngle, FlxG.width);
					var intersects = laserCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.objects));
					if (intersects.length > 0) {
						for (i in intersects) {
							if (Collide.bodyInteractsWithColor(i.body, laserColor)) {
								if (i.closest.distance < laserLength) {
									laserLength = i.closest.distance;
									emitter.setPosition(i.closest.hit.x, i.closest.hit.y);
								}
							}
							i.put();
						}
					}

					var laser = new LaserBeam(emitterPoint.x, emitterPoint.y, laserAngle, laserLength, laserColor);
					PlayState.ME.addLaser(laser); 
					FlxG.cameras.shake(.01, .5);
					new FlxTimer().start(LASER_TIME, (t) -> {
						emitter.emitting = false;
						laser.kill();
						shooting = false;
						// active = true;
						laserFinished();
					});
					shooting = true;
					// active = false;
					cooldown = 0;
					charging = 0;
					laserFired();
				}
			}
		}

		getGraphicMidpoint(tmp);
		distanceFromCam = PlayState.ME.objectCam.distanceFromBounds(tmp);
		tmp.set(emitter.x, emitter.y);
		emitterDistanceFromCam = PlayState.ME.objectCam.distanceFromBounds(tmp);
		FlxG.watch.addQuick('dfc: ', distanceFromCam);
		FlxG.watch.addQuick('dfc E: ', emitterDistanceFromCam);

		volume = Math.max(0, (maxDistanceToHear - Math.min(distanceFromCam, emitterDistanceFromCam))) / maxDistanceToHear;
		FlxG.watch.addQuick('laserVolume: ', volume);
	}

	function cooldownUpdate() {}

	function chargeUpdate() {}

	function cooldownEnd() {}

	function laserFired() {}

	function laserFinished() {}
}