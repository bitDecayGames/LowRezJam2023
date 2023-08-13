package entities.enemy;

import echo.Body;
import flixel.FlxG;
import entities.enemy.BaseLaser.BaseLaserOptions;
import echo.math.Vector2;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import states.PlayState;

#if debug_turret
import flixel.FlxG;
#end

using echo.FlxEcho;

class LaserTurret extends BaseLaser {
	var aimAngle:Float = 0;
	var startLockAngle:Float = Math.NaN;

	var lastAngle:Float = 0;
	var forceAngularUpdate:Bool = false;
	var angleUpdate:Float = -1;

	var maxChaseAngleVelocity = 70;

	public function new(options:BaseLaserOptions) {
		super(options);

		laserStartOffset.set(16, 0);
	}

	override function configSprite() {
		loadGraphic(AssetPaths.rotatingTurret__png);
	}

	override function makeBody():Body {
		return this.add_body({
			x: x,
			y: y,
			kinematic: true,
			rotation: initialDir,
			shape: {
				type: CIRCLE,
				radius: 15,
			}
		});
	}

	override function update(elapsed:Float) {
		#if debug_turret
		FlxG.watch.addQuick('Cooldown: ', cooldown);
		FlxG.watch.addQuick('Charge: ', charging);
		#end

		lastAngle = body.rotation;

		if (forceAngularUpdate) {
			body.rotation += angleUpdate * elapsed;
			laserAngle += angleUpdate * elapsed;
		} else {
			var playerBounds = PlayState.ME.player.body.bounds();
			var playerCenter = new Vector2((playerBounds.min_x + playerBounds.max_x) / 2, (playerBounds.min_y + playerBounds.max_y) / 2);
			var laserAim = playerCenter;
			var midpoint = getGraphicMidpoint();
			var vector = FlxPoint.get(laserAim.x, laserAim.y);
			aimAngle = vector.degreesFrom(midpoint);
	
			var curAngle = body.rotation;
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
				body.rotation = curAngle;
			}
		}

		// #if debug_turret
		// FlxG.watch.addQuick('curAngle: ', curAngle);
		// FlxG.watch.addQuick('aimAngle: ', aimAngle);
		// #end

		super.update(elapsed);
	}

	override function cooldownEnd() {
		super.cooldownEnd();
		startLockAngle = body.rotation;
		chargeSoundId = FmodManager.PlaySoundWithReference(FmodSFX.LaserTurretCharge2);
	}

	override function cooldownUpdate() {
		super.cooldownUpdate();
		body.rotation = FlxMath.lerp(body.rotation, aimAngle, Math.min(1, cooldown / COOLDOWN_TIME / 5));
		laserAngle = body.rotation;
	}

	override function chargeUpdate() {
		super.chargeUpdate();
		slowFollow(charging / CHARGE_TIME);
	}

	override function laserFired() {
		super.laserFired();
		blastSoundId = FmodManager.PlaySoundWithReference(FmodSFX.LaserTurretBlast3);
		startLockAngle = body.rotation;
		forceAngularUpdate = true;
		angleUpdate = (body.rotation - lastAngle) / FlxG.elapsed; // an approximation of per-frame angle change
		if (Math.abs(angleUpdate) > maxChaseAngleVelocity) {
			angleUpdate = maxChaseAngleVelocity * (angleUpdate < 0 ? -1 : 1);
		}
	}

	override function laserFiringUpdate() {
		super.laserFiringUpdate();
		// angle += forceAngularUpdate;
		// tracking behaves the same as when charging
	}

	override function laserFinished() {
		super.laserFinished();
		forceAngularUpdate = false;
	}

	function slowFollow(ratio:Float) {
		body.rotation = FlxMath.lerp(startLockAngle, aimAngle, Math.min(.8, ratio));
		laserAngle = body.rotation;
	}
}