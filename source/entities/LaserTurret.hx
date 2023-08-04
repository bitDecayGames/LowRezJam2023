package entities;

import flixel.util.FlxTimer;
import echo.FlxEcho;
import echo.math.Vector2;
import echo.Line;
import collision.Color;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.effects.particles.FlxEmitter;
import flixel.math.FlxPoint;
import states.PlayState;
import flixel.FlxSprite;

class LaserTurret extends FlxSprite {
	public var emitter:FlxEmitter;
	
	var emitterPoint = FlxPoint.get();

	var laserColor:Color;

	var COOLDOWN_TIME = 10.0;
	var cooldown = 0.0;
	var CHARGE_TIME = 3;
	var charging = 0.0;

	var startLockAngle:Float;

	public function new(X:Float, Y:Float, laserColor:Color) {
		super(X-16, Y-16);
		this.laserColor = laserColor;

		// TODO: Load animated laser
		loadGraphic(AssetPaths.laser_turret_icon__png);

		emitterPoint.set(16, 0);

		emitter = new FlxEmitter(X, Y);
		emitter.loadParticles(AssetPaths.simple_round__png);
		emitter.color.set(laserColor.toFlxColor());
		emitter.lifespan.set(.1, .25);
		emitter.scale.set(.1, .1, .5, .5, .8, .8, 1, 1);
		emitter.alpha.set(.1, 1, .1, 1);
		emitter.start(false, .05);
		emitter.emitting = false;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		FlxG.watch.addQuick('Cooldown: ', cooldown);
		FlxG.watch.addQuick('Charge: ', charging);

		var playerBounds = PlayState.ME.player.body.bounds();
		var playerCenter = new Vector2((playerBounds.min_x + playerBounds.max_x) / 2, (playerBounds.min_y + playerBounds.max_y) / 2);
		var laserAim = playerCenter;
		var midpoint = getGraphicMidpoint();
		var vector = FlxPoint.get(laserAim.x, laserAim.y);
		var aimAngle = vector.degreesFrom(midpoint);

		// TODO: This aim angle behaves oddly when you dance around 180 degrees
		// off from the right side.
		FlxG.watch.addQuick('aimAngle: ', aimAngle);

		if (cooldown < COOLDOWN_TIME) {
			angle = FlxMath.lerp(angle, aimAngle, Math.min(1, cooldown / COOLDOWN_TIME / 5));

			cooldown += elapsed;
			if (cooldown >= COOLDOWN_TIME) {
				startLockAngle = angle;
				emitter.emitting = true;
				// TODO(SFX): laser begins charging
			}

			emitterPoint.set(16, 0).pivotDegrees(FlxPoint.weak(), angle).add(x + width/2, y + height/2);
			emitter.setPosition(emitterPoint.x, emitterPoint.y);
		} else {
			charging += elapsed;
			angle = FlxMath.lerp(startLockAngle, aimAngle, Math.min(.8, charging / CHARGE_TIME));

			if (charging >= CHARGE_TIME) {
				var laserLength:Float = FlxG.width;
				var laserCast = Line.get_from_vector(new Vector2(emitterPoint.x, emitterPoint.y), angle, FlxG.width);
				var intersects = laserCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.objects));
				if (intersects.length > 0) {
					for (i in intersects) {
						if (i.closest.distance < laserLength) {
							laserLength = i.closest.distance;
							emitter.setPosition(i.closest.hit.x, i.closest.hit.y);
						}
						i.put();
					}
				}

				// TODO(SFX): laser fires
				var laser = new LaserBeam(emitterPoint.x, emitterPoint.y, angle, laserLength, laserColor);
				PlayState.ME.addLaser(laser);
				FlxG.camera.shake(.01, .5);
				new FlxTimer().start((t) -> {
					emitter.emitting = false;
					laser.kill();
					active = true;
				});
				active = false;
				cooldown = 0;
				charging = 0;
			}
		}
	}
}