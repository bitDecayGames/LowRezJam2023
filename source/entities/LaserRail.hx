package entities;

import bitdecay.flixel.spacial.Cardinal;
import loaders.Aseprite;
import loaders.AsepriteMacros;
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

typedef LaserOptions = {
	spawnX: Float,
	spawnY: Float,
	dir: Cardinal,
	path: Array<FlxPoint>,
	color: Color,
}

class LaserRail extends FlxSprite {
	private static var anims = AsepriteMacros.tagNames("assets/aseprite/crawlingTurret.json");

	public var emitter:FlxEmitter;
	
	var destPointIndex = 0;
	var pathPoints:Array<FlxPoint>;
	var speed:Float;

	var emitterPoint = FlxPoint.get();

	var laserAngle:Float;
	var laserColor:Color;

	var COOLDOWN_TIME = 5.0;
	var cooldown = 0.0;
	var CHARGE_TIME = 1.5;
	var charging = 0.0;

	var startLockAngle:Float;

	public function new(options:LaserOptions) {
		var spawnPoint = FlxPoint.get(options.spawnX, options.spawnY);
		var adjust = FlxPoint.get(16, 16);
		spawnPoint.addPoint(adjust);
		super(spawnPoint.x, spawnPoint.y);
		this.laserColor = options.color;
		angle = options.dir + 180;
		laserAngle = options.dir + 270;

		this.pathPoints = options.path;
		for (p in pathPoints) {
			p.addPoint(adjust);
		}
		pathPoints.push(spawnPoint);
		this.path = new FlxPath();
		this.path.start(pathPoints, 50, FlxPathType.YOYO);

		Aseprite.loadAllAnimations(this, AssetPaths.crawlingTurret__json);

		animation.play(anims.move);

		emitterPoint.set(0, 8);

		emitter = new FlxEmitter(options.spawnX + emitterPoint.x, options.spawnY + emitterPoint.y);
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

			emitterPoint.set(0, 8).pivotDegrees(FlxPoint.weak(), angle).add(x + width/2, y + height/2);
			emitter.setPosition(emitterPoint.x, emitterPoint.y);
		} else {
			charging += elapsed;
			
			if (charging >= CHARGE_TIME) {
				var laserLength:Float = FlxG.width;
				var laserCast = Line.get_from_vector(new Vector2(emitterPoint.x, emitterPoint.y), laserAngle, FlxG.width);
				var intersects = laserCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.objects));
				if (intersects.length > 0) {
					for (i in intersects) {
						if (i.closest.distance < laserLength) {
							laserLength = i.closest.distance;
							emitter.setPosition(i.closest.hit.x, i.closest.hit.y);
						}
						i.put();
					}
				}

				// TODO(SFX): laser fires
				var laser = new LaserBeam(emitterPoint.x, emitterPoint.y, laserAngle, laserLength, laserColor);
				PlayState.ME.addLaser(laser); 
				FlxG.cameras.shake(.01, .5);
				new FlxTimer().start(0.5, (t) -> {
					emitter.emitting = false;
					laser.kill();
					active = true;
					path.active = true;
				});
				active = false;
				cooldown = 0;
				charging = 0;
			}
		}

		if (velocity.x == 0) {
			animation.pause();
		} else {
			animation.resume();
		}

		flipX = velocity.x > 0;
	}
}