package entities.enemy;

import entities.enemy.BaseLaser.BaseLaserOptions;
import echo.Body;
import collision.Collide;
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

class LaserTurret extends BaseLaser {
	var aimAngle:Float = 0;
	var startLockAngle:Float = Math.NaN;

	public function new(options:BaseLaserOptions) {
		super(options);
	}

	override function configSprite() {
		loadGraphic(AssetPaths.rotatingTurret__png);
	}

	override function update(elapsed:Float) {
		#if debug_turret
		FlxG.watch.addQuick('Cooldown: ', cooldown);
		FlxG.watch.addQuick('Charge: ', charging);
		#end

		var playerBounds = PlayState.ME.player.body.bounds();
		var playerCenter = new Vector2((playerBounds.min_x + playerBounds.max_x) / 2, (playerBounds.min_y + playerBounds.max_y) / 2);
		var laserAim = playerCenter;
		var midpoint = getGraphicMidpoint();
		var vector = FlxPoint.get(laserAim.x, laserAim.y);
		aimAngle = vector.degreesFrom(midpoint);

		var curAngle = angle;
		if (Math.abs(aimAngle - curAngle) > 180) {
			 if (curAngle > aimAngle) {
				// if we aren't locked on, adjust our angle.
				// if we ARE locked on, adjust our aim angle
				if (Math.isNaN(startLockAngle)) {
					curAngle -= 360;
				} else {
					aimAngle += 360;
				}
			} else {
				if (Math.isNaN(startLockAngle)) {
					curAngle += 360;
				} else {
					aimAngle -= 360;
				}
			}
			angle = curAngle;
		}

		// TODO: This aim angle behaves oddly when you dance around 180 degrees
		// off from the right side.
		#if debug_turret
		FlxG.watch.addQuick('curAngle: ', curAngle);
		FlxG.watch.addQuick('aimAngle: ', aimAngle);
		#end

		super.update(elapsed);
	}

	override function cooldownEnd() {
		super.cooldownEnd();
		startLockAngle = angle;
		FmodManager.PlaySoundOneShot(FmodSFX.LaserStationaryCharge);
	}

	override function cooldownUpdate() {
		super.cooldownUpdate();
		angle = FlxMath.lerp(angle, aimAngle, Math.min(1, cooldown / COOLDOWN_TIME / 5));
	}

	override function chargeUpdate() {
		super.chargeUpdate();
		angle = FlxMath.lerp(startLockAngle, aimAngle, Math.min(.8, charging / CHARGE_TIME));
		laserAngle = angle;

		emitterPoint.set(16, 0).pivotDegrees(FlxPoint.weak(), angle).add(x + width/2, y + height/2);
		emitter.setPosition(emitterPoint.x, emitterPoint.y);
	}

	override function laserFired() {
		super.laserFired();
		FmodManager.PlaySoundOneShot(FmodSFX.LaserTurretBlast3);
		startLockAngle = Math.NaN;
	}
}