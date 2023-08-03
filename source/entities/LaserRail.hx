package entities;

import flixel.util.FlxTimer;
import flixel.path.FlxPath;
import flixel.math.FlxPoint;
import states.PlayState;
import echo.FlxEcho;
import echo.math.Vector2;
import echo.Line;
import flixel.FlxG;
import flixel.effects.particles.FlxEmitter;
import collision.Color;
import flixel.FlxSprite;

class LaserRail extends FlxSprite {
	public var emitter:FlxEmitter;
	
	var destPointIndex = 0;
	var pathPoints:Array<FlxPoint>;
	var speed:Float;

	var emitterPoint = FlxPoint.get();

	var laserAngle:Float;
	var laserColor:Color;

	var COOLDOWN_TIME = 10.0;
	var cooldown = 0.0;
	var CHARGE_TIME = 3;
	var charging = 0.0;

	var startLockAngle:Float;

	public function new(X:Float, Y:Float, laserColor:Color, path:Array<FlxPoint>) {
		super(X, Y);
		// offset.set(16, 16);
		this.laserColor = laserColor;
		// TODO: Accept stating angle for rail laser
		laserAngle = angle + 90;

		this.pathPoints = path;
		this.path = new FlxPath();
		this.path.start(pathPoints, 50, FlxPathType.YOYO);

		// TODO: Load animated laser
		loadGraphic(AssetPaths.laser_rail_icon__png);

		emitterPoint.set(0, 8);

		emitter = new FlxEmitter(X, Y);
		emitter.loadParticles(AssetPaths.simple_round__png);
		emitter.color.set(laserColor.toFlxColor());
		emitter.lifespan.set(.1, .25);
		emitter.scale.set(.1, .1, .5, .5, .8, .8, 1, 1);
		emitter.alpha.set(.1, 1, .1, 1);
		emitter.start(false, .05);
		emitter.emitting = false;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (cooldown < COOLDOWN_TIME) {
			cooldown += elapsed;
			if (cooldown >= COOLDOWN_TIME) {
				emitter.emitting = true;
				this.path.active = false;
				velocity.set();
				// TODO(SFX): laser begins charging
			}
		} else {
			charging += elapsed;
			
			if (charging >= CHARGE_TIME) {
				emitter.emitting = false;
				var laserLength:Float = FlxG.width;
				var laserCast = Line.get_from_vector(new Vector2(emitterPoint.x, emitterPoint.y), laserAngle, FlxG.width);
				var intersects = laserCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.objects));
				if (intersects.length > 0) {
					for (i in intersects) {
						laserLength = Math.min(laserLength, i.closest.distance);
						i.put();
					}
				}

				// TODO(SFX): laser fires
				var laser = new LaserBeam(emitterPoint.x, emitterPoint.y, laserAngle, laserLength, laserColor);
				PlayState.ME.addLaser(laser); 
				FlxG.camera.shake(.01, .5);
				new FlxTimer().start(0.5, (t) -> {
					laser.kill();
					active = true;
					path.active = true;
				});
				active = false;
				cooldown = 0;
				charging = 0;
			}
		}

		emitterPoint.set(0, 8).pivotDegrees(FlxPoint.weak(), angle).add(x + width/2, y + height/2);
		emitter.setPosition(emitterPoint.x, emitterPoint.y);
	}
}