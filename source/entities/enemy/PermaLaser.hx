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
			var laserLength:Float = BaseLaser.MAX_CAST_DISTANCE;
			var laserCast = Line.get_from_vector(new Vector2(castStart.x, castStart.y), laserAngle, BaseLaser.MAX_CAST_DISTANCE);
			var intersects = laserCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.terrainGroup));
			if (intersects.length > 0) {
				for (i in intersects) {
					if (Collide.bodyInteractsWithColor(i.body, laserColor)) {
						if (i.closest.distance < laserLength) {
							laserLength = i.closest.distance;
							emitter = new LaserParticle(i.closest.hit.x, i.closest.hit.y, laserColor);
							emitter.emitting = true;
							PlayState.ME.addParticle(emitter);
						}
					}
					i.put();
				}
			}
			var laser = new LaserBeam(castStart.x, castStart.y, laserAngle, laserLength, laserColor);
			PlayState.ME.addLaser(laser);
		}
	}
}