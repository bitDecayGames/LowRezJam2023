package entities.enemy;

import flixel.math.FlxPoint;
import loaders.Aseprite;
import entities.particles.LaserParticle;
import collision.Color;
import states.PlayState;
import bitdecay.flixel.spacial.Cardinal;
import flixel.FlxSprite;

using echo.FlxEcho;
using bitdecay.flixel.extensions.FlxCameraExt;
using extension.CamExt;


class PermaLaser extends FlxSprite {
	public var emitter:LaserParticle;

	public var laserColor:Color;
	
	var beamId = "";
	var tmp = FlxPoint.get();
	var distanceFromCam = 0.0;
	var maxDistanceToHear = 256;
	public var volume:Float = 0.0;

	public function new(X:Float, Y:Float, dir:Cardinal, color:Color) {
		super(X, Y);
		this.laserColor = color;
		
		beamId = FmodManager.PlaySoundWithReference(FmodSFX.LaserStaticHum2);

		Aseprite.loadAllAnimations(this, AssetPaths.permaLaser__json);
		angle = dir - 180;
	}

	var began = false;

	@:access(echo.FlxEcho)
	override function update(elapsed:Float) {
		super.update(elapsed);


		if (PlayState.ME.playerDying) {
			stopSound();
		}


		getGraphicMidpoint(tmp);
		distanceFromCam = PlayState.ME.objectCam.distanceFromBounds(tmp);
		volume = Math.max(0, (maxDistanceToHear - distanceFromCam)) / maxDistanceToHear;
		if (beamId != ""){
			FmodManager.SetEventParameterOnSound(beamId, "volume", volume);
		}

		if (!began) {
			began = true;

			var laserAngle = angle + 90;
			var castStart = getPosition().add(width / 2, height / 2);
			var laser = new LaserBeam(castStart.x, castStart.y, laserAngle, 1, laserColor);
			laser.beginFire();
			laser.updatePosition(castStart.x, castStart.y, laserAngle);

			emitter = new LaserParticle(laser.impactPoint.x, laser.impactPoint.y, laserColor);
			emitter.setImpactAngle(laser.impactNormal.degrees);
			emitter.emitting = true;
			PlayState.ME.addLaser(laser);
			PlayState.ME.addParticle(emitter);

			laser.body.update_body_object();
		}
	}

	override function destroy() {
		super.destroy();
		stopSound();
	}

	function stopSound() {
		FmodManager.StopSoundImmediately(beamId);
		beamId = "";
	}
}