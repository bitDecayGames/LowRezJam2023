package entities.enemy;

import entities.particles.LaserParticle;
import collision.Collide;
import bitdecay.flixel.spacial.Cardinal;
import loaders.Aseprite;
import loaders.AsepriteMacros;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import states.PlayState;
import echo.FlxEcho;
import echo.math.Vector2;
import echo.Line;
import flixel.FlxG;
import flixel.effects.particles.FlxEmitter;
import collision.Color;
import flixel.FlxSprite;

typedef LaserStationaryOptions = {
	spawnX: Float,
	spawnY: Float,
	dir: Cardinal,
	color: Color,
	rest: Float,
	laserTime: Float,
}

class LaserStationary extends FlxSprite {
	private static var anims = AsepriteMacros.tagNames("assets/aseprite/stationaryTurret.json");

	public var emitter:FlxEmitter;
	var emitterPoint = FlxPoint.get();

	var laserColor:Color;
	var laserAngle:Float;

	var COOLDOWN_TIME = 5.0;
	var cooldown = 0.0;
	var CHARGE_TIME = 1.5;
	var charging = 0.0;

	var LASER_TIME = 1.0;

	public function new(options:LaserStationaryOptions) {
		var spawnPoint = FlxPoint.get(options.spawnX, options.spawnY);
		super(spawnPoint.x, spawnPoint.y);
		this.laserColor = options.color;
		angle = options.dir - 90;
		laserAngle = options.dir + 270;

		Aseprite.loadAllAnimations(this, AssetPaths.stationaryTurret__json);
		animation.frameIndex = 0;

		COOLDOWN_TIME = options.rest;
		LASER_TIME = options.laserTime;

		emitterPoint.set(0, 8);
		emitter = new LaserParticle(options.spawnX + emitterPoint.x, options.spawnY + emitterPoint.y, laserColor);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (cooldown < COOLDOWN_TIME) {
			cooldown += elapsed;
			if (cooldown >= COOLDOWN_TIME) {
				emitter.emitting = true;
				velocity.set();
				// TODO(SFX): laser begins charging
			}

			emitterPoint.set(0, 8).pivotDegrees(FlxPoint.weak(), angle - 90).add(x + width/2, y + height/2);
			emitter.setPosition(emitterPoint.x, emitterPoint.y);
		} else {
			charging += elapsed;
			
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

				// TODO(SFX): laser fires
				var laser = new LaserBeam(emitterPoint.x, emitterPoint.y, laserAngle, laserLength, laserColor);
				PlayState.ME.addLaser(laser); 
				FlxG.cameras.shake(.01, .5);
				new FlxTimer().start(LASER_TIME, (t) -> {
					emitter.emitting = false;
					laser.kill();
					active = true;
				});
				active = false;
				cooldown = 0;
				charging = 0;
			}
		}

		if (velocity.x == 0) {
			animation.pause();
		} else {
			animation.resume();
		}

		flipX = velocity.x > 0;
	}
}