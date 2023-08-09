package entities.enemy;

import entities.particles.DeathParticles;
import states.PlayState;
import echo.data.Data.CollisionData;
import flixel.math.FlxPoint;
import echo.Body;
import collision.Color;
import collision.ColorCollideSprite;

using echo.FlxEcho;

class LaserBeam extends ColorCollideSprite {
	var spawn:FlxPoint;
	var length:Float;
	var beamColor:Color;
	var laserAngle:Float;

	public function new(X:Float, Y:Float, angle:Float, length:Float, color:Color) {
		spawn = FlxPoint.get(X, Y).addPoint(FlxPoint.get(1, 0).scale(length/2.0).pivotDegrees(FlxPoint.weak(), angle));
		this.length = length;
		this.beamColor = color;
		this.laserAngle = angle;
		super(spawn.x, spawn.y, color);
	}

	override function configSprite() {
		// XXX: just make this long enough to cover screen
		// TODO: Do a ray cast and see what the laser would hit in the world
		// TODO: See the normal and have particles only shoot off the surface the right direction
		makeGraphic(Math.ceil(length), 8, beamColor.toFlxColor());
		alpha = 0.8;
		// offset.set(0, 4);
	}

	override function makeBody():Body {
		return this.add_body({
			x: spawn.x,
			y: spawn.y,
			// mass: STATIC,
			kinematic: true,
			rotation: laserAngle,
			shape: {
				type: RECT,
				width: length,
				height: 2,
				solid: false,
			}
		});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		if (other.object is Player) {
			// TODO: Drama / death sequence
			PlayState.ME.playerDied();
		}
	}

	override function kill() {
		this.remove_object(true);
		super.kill();
	}
}