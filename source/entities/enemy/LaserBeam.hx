package entities.enemy;

import echo.shape.Rect;
import collision.Collide;
import echo.math.Vector2;
import echo.Line;
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
	public var impactPoint:FlxPoint = FlxPoint.get();

	// TODO: See the normal and have particles only shoot off the surface the right direction
	public function new(X:Float, Y:Float, angle:Float, length:Float, color:Color) {
		spawn = FlxPoint.get(X, Y).addPoint(FlxPoint.get(1, 0).scale(length/2.0).pivotDegrees(FlxPoint.weak(), angle));
		this.length = length;
		this.beamColor = color;
		this.laserAngle = angle;
		super(spawn.x, spawn.y, color);
	}

	override function configSprite() {
		// we'll scale the width to match beam length as needed
		makeGraphic(1, 8, beamColor.toFlxColor());
		alpha = 0.5;
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

	public function updatePosition(startX:Float, startY:Float, angle:Float) {
		var laserLength:Float = BaseLaser.MAX_CAST_DISTANCE;
		var laserCast = Line.get_from_vector(new Vector2(startX, startY), angle, BaseLaser.MAX_CAST_DISTANCE);
		var intersects = laserCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.terrainGroup));
		impactPoint.set(startX, startY);
		if (intersects.length > 0) {
			for (i in intersects) {
				if (Collide.bodyInteractsWithColor(i.body, beamColor)) {
					if (i.closest.distance < laserLength) {
						laserLength = i.closest.distance;
						impactPoint.set(i.closest.hit.x, i.closest.hit.y);
						// emitter.setPosition(i.closest.hit.x, i.closest.hit.y);
					}
				}
				i.put();
			}
		}

		laserCast.put();
		spawn.set(startX, startY).add(impactPoint.x, impactPoint.y).scale(0.5);
		body.x = spawn.x;
		body.y = spawn.y;
		body.rotation = angle;
		cast(body.shape, Rect).width = laserLength;
		scale.set(laserLength, 1);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		if (other.object is Player) {
			PlayState.ME.playerDied();
		}
	}
}