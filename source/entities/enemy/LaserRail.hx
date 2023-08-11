package entities.enemy;

import entities.enemy.BaseLaser.LaserRailOptions;
import collision.Collide;
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

class LaserRail extends BaseLaser {
	private static var anims = AsepriteMacros.tagNames("assets/aseprite/crawlingTurret.json");

	var destPointIndex = 0;
	var pathPoints:Array<FlxPoint>;
	var speed:Float;
	var pauseOnFire:Bool;
	var shootOnNode:Bool;

	public function new(options:LaserRailOptions) {
		super(options);
		
		var spawnPoint = FlxPoint.get(options.spawnX, options.spawnY);
		var adjust = FlxPoint.get(16, 16);
		this.pathPoints = options.path;
		for (p in pathPoints) {
			p.addPoint(adjust);
		}
		pathPoints.push(spawnPoint.addPoint(adjust));
		this.path = new FlxPath();
		this.path.start(pathPoints, 50, FlxPathType.LOOP_FORWARD);

		pauseOnFire = options.pauseOnFire;
		shootOnNode = options.shootOnNode;
	}

	override function configSprite() {
		Aseprite.loadAllAnimations(this, AssetPaths.crawlingTurret__json);
		animation.play(anims.move);
	}

	override function cooldownEnd() {
		super.cooldownEnd();
		velocity.set();
		if (pauseOnFire) {
			this.path.active = false;
		}
		FmodManager.PlaySoundOneShot(FmodSFX.LaserStationaryCharge);
	}

	override function laserFired() {
		super.laserFired();
		FmodManager.PlaySoundOneShot(FmodSFX.LaserStationaryBlast2);
	}

	override function laserFinished() {
		super.laserFinished();
		path.active = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (velocity.x == 0) {
			animation.pause();
		} else {
			animation.resume();
		}

		flipX = velocity.x > 0;
	}
}