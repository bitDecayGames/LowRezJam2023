package entities.enemy;

import loaders.Aseprite;
import entities.particles.LaserParticle;
import collision.Color;
import collision.Collide;
import states.PlayState;
import echo.FlxEcho;
import echo.math.Vector2;
import echo.Line;
import flixel.FlxG;
import bitdecay.flixel.spacial.Cardinal;
import flixel.FlxSprite;

class PermaLaser extends FlxSprite {
	public var emitter:LaserParticle;

	public var laserColor:Color;

	public function new(X:Float, Y:Float, dir:Cardinal, color:Color) {
		super(X, Y);
		this.laserColor = color;

		Aseprite.loadAllAnimations(this, AssetPaths.permaLaser__json);
		angle = dir - 180;
	}

	var began = false;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!began) {
			began = true;

			var laserAngle = angle + 90;
			var castStart = getPosition().add(width / 2, height / 2);
			var laser = new LaserBeam(castStart.x, castStart.y, laserAngle, 1, laserColor);
			laser.updatePosition(castStart.x, castStart.y, laserAngle);

			emitter = new LaserParticle(laser.impactPoint.x, laser.impactPoint.y, laserColor);
			emitter.setImpactAngle(laser.impactNormal.degrees);
			emitter.emitting = true;
			PlayState.ME.addLaser(laser);
			PlayState.ME.addParticle(emitter);
		}
	}
}