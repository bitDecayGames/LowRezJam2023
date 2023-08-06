package states;

import flixel.math.FlxRect;
import entities.Transition;
import openfl.display.BlendMode;
import collision.TileTypes;
import progress.Collected;
import haxe.CallStack.StackItem;
import helpers.CardinalMaker;
import entities.LaserBeam;
import flixel.math.FlxPoint;
import collision.Collide;
import collision.ColorCollideSprite;
import echo.util.AABB;
import echo.util.TileMap;
import echo.Echo;
import levels.ogmo.Level;
import flixel.group.FlxGroup;
import echo.FlxEcho;
import collision.Constants;
import collision.Color;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Platform;
import flixel.FlxCamera;
import entities.Item;
import flixel.util.FlxColor;
import debug.DebugLayers;
import achievements.Achievements;
import flixel.addons.transition.FlxTransitionableState;
import signals.Lifecycle;
import entities.Player;
import flixel.FlxSprite;
import flixel.FlxG;
import bitdecay.flixel.debug.DebugDraw;

using states.FlxStateExt;
using echo.FlxEcho;

class PlayState extends FlxTransitionableState {
	public static var ME:PlayState;

	var lastLevel:String;
	var lastSpawnEntity:String;

	public var player:Player;
	public var dbgCam:FlxCamera;
	
	public var pendingObjects = new Array<FlxObject>();
	public var pendingLasers = new Array<FlxObject>();

	public var playerGroup = new FlxGroup();
	public var terrainGroup = new FlxGroup();
	public var objects = new FlxGroup();
	public var lasers = new FlxGroup();
	public var particles = new FlxGroup();

	var softFocusBounds:FlxRect;

	public function new() {
		super();
		ME = this;
	}

	override public function create() {
		super.create();
		Lifecycle.startup.dispatch();

		// main will do this, but if we are dev'ing and going straight to the play screen, it may not be done yet
		Collected.initialize();

		FlxEcho.init({width: FlxG.width, height: FlxG.height, gravity_y: 24 * Constants.BLOCK_SIZE});

		#if debug
		FlxEcho.draw_debug = true;
		#end

		FlxG.camera.bgColor = FlxColor.GRAY.getDarkened(0.8);

		dbgCam = new FlxCamera();
		dbgCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(dbgCam, false);

		add(terrainGroup);
		add(objects);
		add(playerGroup);
		add(lasers);
		add(particles);

		// TODO: Load them at some checkpoint if they restart the game?
		var checkpointRoom = Collected.getCheckpointLevel();
		if (checkpointRoom != null) {
			var checkpointEntity = Collected.getCheckpointEntity();
			loadLevel(checkpointRoom, checkpointEntity);
		} else {
			loadLevel("Level_0");
		}
	}

	public function resetLevel() {
		loadLevel(lastLevel, lastSpawnEntity);
	}

	@:access(echo.FlxEcho)
	public function loadLevel(levelID:String, ?entityID:String) {
		lastLevel = levelID;
		lastSpawnEntity = entityID;

		Collected.setLastCheckpoint(levelID, entityID);

		FlxEcho.clear();

		terrainGroup.forEach((f) -> f.destroy());
		terrainGroup.clear();

		objects.forEach((f) -> f.destroy());
		objects.clear();

		lasers.forEach((f) -> f.destroy());
		lasers.clear();

		particles.forEach((f) -> f.destroy());
		particles.clear();

		playerGroup.forEach((f) -> f.destroy());
		playerGroup.clear();
		player = null;
		add(objects);

		var level = new levels.ldtk.Level(levelID);

		terrainGroup.add(level.terrainGfx);

		softFocusBounds = FlxRect.get(0, 0, level.bounds.width, level.bounds.height);
		FlxEcho.instance.world.set(0, 0, level.bounds.width, level.bounds.height);

		TileTypes.buildTiles(level, objects);
		
		for (o in level.objects) {
			o.add_to_group(objects);
		}

		var extraSpawnLogic:Void->Void = null;
		var spawnPoint = FlxPoint.get();
		if (entityID != null) {
			var matches = level.raw.l_Objects.all_Door.filter((d) -> {return d.iid == entityID;});
			if (matches.length != 1) {
				var msg = 'expected door in level ${levelID} with iid ${entityID}, but got ${matches.length} matches';
				QuickLog.critical(msg);
			}
			var spawn = matches[0];
			var t:Transition = null;
			for (o in objects) {
				if (o is Transition) {
					t = cast o;
					if (t.doorID == spawn.iid) {
						// this is the door we are coming into, so open it
						t.open();
					}
				}
			}
			var spawnDir = CardinalMaker.fromString(spawn.f_access_dir.getName());
			spawnPoint.set(spawn.pixelX, spawn.pixelY - 4);
			// TODO: find a better way to calculate this offset
			spawnPoint.addPoint(spawnDir.asVector().scale(-48));

			FlxEcho.updates = false;
			FlxEcho.instance.active = false;
			extraSpawnLogic = () -> {
				player.transitionWalk(spawnDir, () -> {
					FlxEcho.updates = true;
					FlxEcho.instance.active = true;
					t.close();
				});
			}
		} else if (level.raw.l_Objects.all_Spawn.length > 0) {
			var rawSpawn = level.raw.l_Objects.all_Spawn[0];
			spawnPoint.set(rawSpawn.pixelX, rawSpawn.pixelY);
		} else {
			QuickLog.critical('no spawn found, and no entity provided. Cannot spawn player');
		}

		player = new Player(spawnPoint.x, spawnPoint.y);
		player.add_to_group(playerGroup);
		if (extraSpawnLogic != null) {
			extraSpawnLogic();
		}

		camera.focusOn(player.getGraphicMidpoint());
		dbgCam.scroll.copyFrom(camera.scroll);

		softFollowPlayer();

		for (emitter in level.emitters) {
			particles.add(emitter);
		}

		// We need to cache our non-interacting collisions to avoid glitchy
		// physics if they change color after they overlap with a valid color
		// match.
		FlxEcho.listen(playerGroup, objects, {
			condition: Collide.colorBodiesDoNotInteract,
			separate: false,
			enter: (a, b, o) -> {
				Collide.ignoreCollisionsOfBColor(a, b);
			},
			exit: (a, b) -> {
				Collide.restoreCollisions(a, b);
			}
		});

		FlxEcho.listen(playerGroup, lasers, {
			condition: Collide.colorBodiesInteract,
			enter: (a, b, o) -> {
				if (Std.isOfType(a.object, ColorCollideSprite)) {
					cast(a.object, ColorCollideSprite).handleEnter(b, o);
				}
				if (Std.isOfType(b.object, ColorCollideSprite)) {
					cast(b.object, ColorCollideSprite).handleEnter(a, o);
				}
			},
		});

		FlxEcho.listen(playerGroup, objects, {
			condition: Collide.colorBodiesInteract,
			enter: (a, b, o) -> {
				if (Std.isOfType(a.object, ColorCollideSprite)) {
					cast(a.object, ColorCollideSprite).handleEnter(b, o);
				}
				if (Std.isOfType(b.object, ColorCollideSprite)) {
					cast(b.object, ColorCollideSprite).handleEnter(a, o);
				}
			},
			stay: (a, b, o) -> { },
			exit: (a, b) -> {
				if (Std.isOfType(a.object, ColorCollideSprite)) {
					cast(a.object, ColorCollideSprite).handleExit(b);
				}
				if (Std.isOfType(b.object, ColorCollideSprite)) {
					cast(b.object, ColorCollideSprite).handleExit(a);
				}
			},
		});
	}

	public function addLaser(laser:LaserBeam) {
		laser.add_to_group(lasers);
	}

	public function addParticle(o:FlxObject) {
		particles.add(o);
	}

	public function softFollowPlayer() {
		camera.setScrollBoundsRect(0, 0, softFocusBounds.width, softFocusBounds.height);
		dbgCam.setScrollBoundsRect(0, 0, softFocusBounds.width, softFocusBounds.height);
		camera.follow(player, FlxCameraFollowStyle.PLATFORMER, .5);
		dbgCam.follow(player, FlxCameraFollowStyle.PLATFORMER, .5);
	}

	public function hardFollowPlayer(lerp:Float) {
		camera.setScrollBounds(null, null, null, null);
		dbgCam.setScrollBounds(null, null, null, null);
		camera.follow(player, FlxCameraFollowStyle.LOCKON, lerp);
		dbgCam.follow(player, FlxCameraFollowStyle.LOCKON, lerp);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		for (o in pendingObjects) {
			o.add_to_group(objects);
		}
		pendingObjects = [];

		for (l in pendingLasers) {
			l.add_to_group(lasers);
		}
		pendingLasers = [];

		DebugDraw.ME.drawCameraCircle(FlxG.width/2, FlxG.height/2, 2);
	}

	override public function onFocusLost() {
		super.onFocusLost();
		this.handleFocusLost();
	}

	override public function onFocus() {
		super.onFocus();
		this.handleFocus();
	}
}
