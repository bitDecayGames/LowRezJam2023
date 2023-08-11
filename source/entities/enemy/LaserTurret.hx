package entities.enemy;

import flixel.FlxG;
import entities.enemy.BaseLaser.BaseLaserOptions;
import echo.math.Vector2;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import states.PlayState;

#if debug_turret
import flixel.FlxG;
#end

class LaserTurret extends BaseLaser {
	var aimAngle:Float = 0;
	var startLockAngle:Float = Math.NaN;

	var lastAngle:Float = 0;
	var forceAngularUpdate:Bool = false;
	var angleUpdate:Float = -1;

	public function new(options:BaseLaserOptions) {
		super(options);

		laserStartOffset.set(16, 0);
	}

	override function configSprite() {
		loadGraphic(AssetPaths.rotatingTurret__png);
	}

	override function update(elapsed:Float) {
		#if debug_turret
		FlxG.watch.addQuick('Cooldown: ', cooldown);
		FlxG.watch.addQuick('Charge: ', charging);
		#end

		lastAngle = angle;

		if (forceAngularUpdate) {
			angle += angleUpdate * elapsed;
			laserAngle += angleUpdate * elapsed;
		} else {
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
		}

		// #if debug_turret
		// FlxG.watch.addQuick('curAngle: ', curAngle);
		// FlxG.watch.addQuick('aimAngle: ', aimAngle);
		// #end

		super.update(elapsed);
	}

	override function cooldownEnd() {
		super.cooldownEnd();
		startLockAngle = angle;
		chargeSoundId = FmodManager.PlaySoundWithReference(FmodSFX.LaserTurretCharge2);
	}

	override function cooldownUpdate() {
		super.cooldownUpdate();
		angle = FlxMath.lerp(angle, aimAngle, Math.min(1, cooldown / COOLDOWN_TIME / 5));
		laserAngle = angle;
	}

	override function chargeUpdate() {
		super.chargeUpdate();
		slowFollow(charging / CHARGE_TIME);
	}

	override function laserFired() {
		super.laserFired();
		blastSoundId = FmodManager.PlaySoundWithReference(FmodSFX.LaserTurretBlast3);
		startLockAngle = angle;
		forceAngularUpdate = true;
		angleUpdate = (angle - lastAngle) / FlxG.elapsed; // an approximation of per-frame angle change
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
		angle = FlxMath.lerp(startLockAngle, aimAngle, Math.min(.8, ratio));
		laserAngle = angle;
	}
}