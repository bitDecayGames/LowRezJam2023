package entities.enemy;

import echo.Body;
import input.SimpleController;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
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

using echo.FlxEcho;
using extension.CamExt;

typedef BaseLaserOptions = {
	spawnX: Float,
	spawnY: Float,
	dir: Cardinal,
	color: Color,
	rest: Float,
	delay:Float,
}

typedef LaserStationaryOptions = BaseLaserOptions & {
	laserTime: Float,
}

typedef LaserRailOptions = BaseLaserOptions & {
	path: Array<FlxPoint>,
	pauseOnFire: Bool,
	shootOnNode: Bool,
}

class BaseLaser extends ColorCollideSprite {
	public static inline var MAX_CAM_SHAKE = .01;
	public static inline var MAX_CAST_DISTANCE = 600;

	var tmp = FlxPoint.get();

	public var emitter:LaserParticle;
	var laserStartPoint = FlxPoint.get();
	var laserStartOffset = FlxPoint.get(0, 8);

	public var beam:LaserBeam = null;
	var laserColor:Color;
	var laserAngle:Float;

	var COOLDOWN_TIME = 5.0;
	var cooldown = 0.0;
	var CHARGE_TIME = 1.5;
	var charging = 0.0;

	var LASER_TIME = 1.0;

	// controls how far off-screen we can hear things. `volume` curve 
	// is directly based on this value
	var maxDistanceToHear = 256;
	var maxDistanceToShake = 128;
	var chargeSoundId = "";
	var blastSoundId = "";
	var volume = 1.0;
	var shakeAmount = 1.0;
	var distanceFromCam = 0.0;
	var emitterDistanceFromCam = 0.0;

	var shooting = false;

	var initialDir:Float = 0.0;
	var adjust = FlxPoint.get(16, 16);
	
	public function new(options:BaseLaserOptions) {
		initialDir = options.dir + 180;
		options.spawnX += adjust.x;
		options.spawnY += adjust.y;
		
		super(options.spawnX, options.spawnY, EMPTY);
		laserColor = options.color;
		// angle = options.dir + 180;
		laserAngle = (options.dir + 270) % 360;
	
		COOLDOWN_TIME = options.rest;

		// LASER_TIME = options.


		beam = new LaserBeam(laserStartPoint.x, laserStartPoint.y, laserAngle, 1, laserColor);
		beam.visible = false;
		beam.body.active = false;

		emitter = new LaserParticle(options.spawnX + laserStartPoint.x, options.spawnY + laserStartPoint.y, laserColor);
	}

	override function makeBody():Body {
		var xOffset = 0.0;
		var yOffset = -height * .25;

		return this.add_body({
			x: x,
			y: y,
			kinematic: true,
			rotation: initialDir,
			shape: {
				type: RECT,
				width: width,
				height: height / 2,
				offset_x: xOffset,
				offset_y: yOffset,
			}
		});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		body.velocity.set(velocity.x, velocity.y);

		if (chargeSoundId != "") {
			FmodManager.SetEventParameterOnSound(chargeSoundId, "volume", volume);
		}

		if (blastSoundId != "") {
			FmodManager.SetEventParameterOnSound(blastSoundId, "volume", volume);
		}

		if (!shooting) {
			if (cooldown <= COOLDOWN_TIME || (cooldown == 0 && COOLDOWN_TIME == 0)) {
				cooldown += elapsed;
				cooldownUpdate();

				if (cooldown >= COOLDOWN_TIME) {
					emitter.emitting = true;
					cooldownEnd();
				}
			} else {
				charging += elapsed;

				chargeUpdate();
				
				if (charging >= CHARGE_TIME) {
					beam.updatePosition(laserStartPoint.x, laserStartPoint.y, laserAngle);
					updateDistances();

					if (shakeAmount > 0) {
						FlxG.cameras.shake(MAX_CAM_SHAKE * shakeAmount, .5);
					}
					new FlxTimer(PlayState.ME.deltaModTimerMgr).start(LASER_TIME, (t) -> {
						emitter.emitting = false;
						shooting = false;
						FmodManager.StopSoundImmediately(blastSoundId);
						blastSoundId = "";
						beam.body.active = false;
						beam.visible = false;
						laserFinished();
					});
					FmodManager.StopSoundImmediately(chargeSoundId);
					chargeSoundId = "";
					shooting = true;
					beam.body.active = true;
					beam.visible = true;
					
					if (COOLDOWN_TIME == 0) {
						cooldown = 0;
					} else {
						// this keeps any remainder flowing so theystay in sync
						cooldown -= COOLDOWN_TIME;
					}
					charging -= CHARGE_TIME;
					laserFired();
				}
			}
		} else {
			laserFiringUpdate();
		}

		updateEmitterPoint();
		beam.updatePosition(laserStartPoint.x, laserStartPoint.y, laserAngle);
			
		if (shooting) {
			emitter.setPosition(beam.impactPoint.x, beam.impactPoint.y);
			emitter.setImpactAngle(beam.impactNormal.degrees);
		}
		updateDistances();
	}

	function updateEmitterPoint() {
		laserStartPoint.copyFrom(laserStartOffset).pivotDegrees(FlxPoint.weak(), angle).add(x + width/2, y + height/2);
		emitter.setPosition(laserStartPoint.x, laserStartPoint.y);
	}

	function updateDistances() {
		getGraphicMidpoint(tmp);
		distanceFromCam = PlayState.ME.objectCam.distanceFromBounds(tmp);
		tmp.set(emitter.x, emitter.y);
		emitterDistanceFromCam = PlayState.ME.objectCam.distanceFromBounds(tmp);

		volume = Math.max(0, (maxDistanceToHear - Math.min(distanceFromCam, emitterDistanceFromCam))) / maxDistanceToHear;
		shakeAmount = Math.max(0, (maxDistanceToShake - Math.min(distanceFromCam, emitterDistanceFromCam))) / maxDistanceToShake;
		#if debug_laser
		FlxG.watch.addQuick('laserVolume: ', volume);
		#end
	}

	function cooldownUpdate() {}

	function chargeUpdate() {}

	function cooldownEnd() {}

	function laserFired() {}

	function laserFiringUpdate() {}

	function laserFinished() {}
}