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
	public var impactNormal = FlxPoint.get();

	var aimAlpha = 0.2;
	var fireAlpha = 0.5;

	// TODO: See the normal and have particles only shoot off the surface the right direction
	public function new(X:Float, Y:Float, angle:Float, length:Float, color:Color) {
		spawn = FlxPoint.get(X, Y).addPoint(FlxPoint.get(1, 0).scale(length/2.0).pivotDegrees(FlxPoint.weak(), angle));
		this.length = length;
		this.beamColor = color;
		this.laserAngle = angle;
		super(spawn.x, spawn.y, color);
		scale.set(length, 1);
	}

	override function configSprite() {
		// we'll scale the width to match beam length as needed
		makeGraphic(1, 4, beamColor.toFlxColor());
		alpha = aimAlpha;
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

	public function beginCharge() {
		body.active = false;
		visible = true;
		alpha = aimAlpha;
		scale.y = 1;
	}

	public function beginFire() {
		body.active = true;
		visible = true;
		alpha = fireAlpha;
		scale.y = 2;
	}

	public function stop() {
		body.active = false;
		visible = false;
	}

	public function updatePosition(startX:Float, startY:Float, angle:Float) {
		var laserLength:Float = BaseLaser.MAX_CAST_DISTANCE;
		var laserCast = Line.get_from_vector(new Vector2(startX, startY), angle, BaseLaser.MAX_CAST_DISTANCE);
		var intersects = laserCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.terrainGroup));
		impactPoint.set(laserCast.end.x, laserCast.end.y);
		if (intersects.length > 0) {
			for (i in intersects) {
				if (Collide.bodyInteractsWithColor(i.body, beamColor)) {
					if (i.closest.distance < laserLength) {
						impactNormal.set(i.data[0].normal.x, i.data[0].normal.y);
						laserLength = i.closest.distance;
						impactPoint.set(i.closest.hit.x, i.closest.hit.y);
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
		scale.x = laserLength;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		if (other.object is Player) {
			if (checkPlayerHit(cast other.object)) {
				PlayState.ME.playerDied();
			}
		}
	}

	override function handleStay(other:Body, data:Array<CollisionData>) {
		super.handleStay(other, data);

		if (other.object is Player) {
			if (checkPlayerHit(cast other.object)) {
				PlayState.ME.playerDied();
			}
		}
	}

	function checkPlayerHit(player:Player):Bool {
		if (player.topShape.solid == false) {
			if (player.bottomShape.collides(body.shape) == null) {
				// we are crouched and laser only touched the disabled top hitbox
				return false;
			} else {
				return true;
			}
		} else {
			return true;
		}
	}
}