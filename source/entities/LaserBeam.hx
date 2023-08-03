package entities;

import collision.Constants;
import flixel.math.FlxPoint;
import echo.Body;
import flixel.FlxG;
import states.PlayState;
import collision.Color;
import collision.ColorCollideSprite;

using echo.FlxEcho;

class LaserBeam extends ColorCollideSprite {

	public var body:Body;

	public function new(X:Float, Y:Float, angle:Float, length:Float, color:Color) {
		var spawn = FlxPoint.get(X, Y).addPoint(FlxPoint.get(1, 0).scale(length/2.0).pivotDegrees(FlxPoint.weak(), angle));
		
		super(spawn.x, spawn.y, color);

		// XXX: just make this long enough to cover screen
		// TODO: Do a ray cast and see what the laser would hit in the world
		// TODO: See the normal and have particles only shoot off the surface the right direction
		makeGraphic(Math.ceil(length), 8, color.toFlxColor());
		alpha = 0.8;
		// offset.set(0, 4);

		body = this.add_body({
			x: spawn.x,
			y: spawn.y,
			// mass: STATIC,
			kinematic: true,
			shape: {
				type: RECT,
				width: length,
				height: 2,
				solid: false,
			}
		});

		this.angle = angle;
		body.rotation = angle;
		visible = false;
	}

	// XXX: For some reason the object is in the wrong place on the first frame, so just don't render it?
	// TODO: Will this misaligned hitbox still collide in its 'bad spot'?
	var skipOne = true;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (skipOne) {
			skipOne = false;
			return;
		}

		visible = true;
	}

	override function kill() {
		this.remove_object(true);
		super.kill();
	}
}