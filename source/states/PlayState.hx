package states;

import openfl.filters.ShaderFilter;
import shaders.PixelateShader;
import flixel.util.FlxTimer;
import entities.particles.DeathParticles;
import flixel.tweens.FlxTween;
import flixel.FlxBasic;
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

using bitdecay.flixel.extensions.FlxCameraExt;
using states.FlxStateExt;
using echo.FlxEcho;

class PlayState extends FlxTransitionableState {
	public static var ME:PlayState;

	public static var backgroundColor = FlxColor.GRAY.getDarkened(0.8);

	var lastLevel:String;
	var lastSpawnEntity:String;

	public var player:Player;

	public var baseTerrainCam:FlxCamera;
	public var colorCams:Map<Color, FlxCamera> = [];
	public var objectCam:FlxCamera;
	public var dbgCam:FlxCamera;
	
	public var pendingObjects = new Array<FlxObject>();
	public var pendingLasers = new Array<FlxObject>();

	public var playerGroup = new FlxGroup();
	public var terrainGroup = new FlxGroup();
	public var objects = new FlxGroup();
	public var lasers = new FlxGroup();
	public var particles = new FlxGroup();

	public var deltaModIgnorers = new FlxGroup();

	var softFocusBounds:FlxRect;

	var deltaMod = 1.0;
	var deathDeltaMod = 0.1;

	public function new() {
		super();
		ME = this;
	}

	override public function create() {
		super.create();
		Lifecycle.startup.dispatch();

		// main will do this, but if we are dev'ing and going straight to the play screen, it may not be done yet
		Collected.initialize();

		baseTerrainCam = FlxG.camera;
		baseTerrainCam.bgColor = backgroundColor;

		setupColorCameras();

		dbgCam = new FlxCamera();
		dbgCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(dbgCam, false);

		objectCam = makeShaderCamera(EMPTY);
		FlxG.cameras.add(objectCam, false);
		
		// Set up echo last so it draws on top of all of our cameras
		FlxEcho.init({width: FlxG.width, height: FlxG.height, gravity_y: 24 * Constants.BLOCK_SIZE});

		#if debug
		FlxEcho.draw_debug = true;
		#end
		

		add(terrainGroup);
		add(objects);
		add(playerGroup);
		add(lasers);
		add(particles);

		var checkpointRoom = Collected.getCheckpointLevel();
		if (checkpointRoom != null) {
			var checkpointEntity = Collected.getCheckpointEntity();
			loadLevel(checkpointRoom, checkpointEntity);
		} else {
			loadLevel("Level_0");
		}
	}

	function setupColorCameras() {
		var pixelShader = new PixelateShader(Color.EMPTY);
		baseTerrainCam.setFilters( [new ShaderFilter(pixelShader)] ); 

		for (color in Color.asList()) {
			var colorCam = makeShaderCamera(color);
			colorCams.set(color, colorCam);
			FlxG.cameras.add(colorCam, false);
		};
	}

	function makeShaderCamera(c:Color):FlxCamera {
		var cam = new FlxCamera();
		var shader = new PixelateShader(c);
		cam.setFilters( [new ShaderFilter(shader)]);
		cam.bgColor = FlxColor.TRANSPARENT;
		return cam;
	}

	function setCamera(o:FlxBasic) {
		if (o == null || !(o is ColorCollideSprite)) {
			return;
		}
		var ccs:ColorCollideSprite = cast o;
		if (ccs.interactColor != EMPTY) {
			if (colorCams.exists(ccs.interactColor)) {
				ccs.cameras = [colorCams.get(ccs.interactColor)];
			}
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

		var level = new levels.ldtk.Level(levelID);

		terrainGroup.add(level.terrainGfx);

		softFocusBounds = FlxRect.get(0, 0, level.bounds.width, level.bounds.height);
		FlxEcho.instance.world.set(0, 0, level.bounds.width, level.bounds.height);

		var tileObjs = TileTypes.buildTiles(level);
		for (t in tileObjs) {
			t.add_to_group(objects);
			setCamera(t);
		}
		
		for (o in level.objects) {
			o.add_to_group(objects);
			o.camera = objectCam;
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
			spawnPoint.set(spawn.pixelX, spawn.pixelY - 2); // TODO: Adjust this so player walks out at correct height
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
		deltaModIgnorers.add(player);
		if (extraSpawnLogic != null) {
			extraSpawnLogic();
		}

		baseTerrainCam.focusOn(player.getGraphicMidpoint());
		dbgCam.scroll.copyFrom(baseTerrainCam.scroll);

		softFollowPlayer();

		for (emitter in level.emitters) {
			addParticle(emitter, false);
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
			stay: (a, b, o) -> {
				if (Std.isOfType(a.object, ColorCollideSprite)) {
					cast(a.object, ColorCollideSprite).handleStay(b, o);
				}
				if (Std.isOfType(b.object, ColorCollideSprite)) {
					cast(b.object, ColorCollideSprite).handleStay(a, o);
				}
			},
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
		laser.camera = objectCam;
	}

	public function addParticle(o:FlxBasic, bypassDelta:Bool = false) {
		particles.add(o);
		particles.camera = objectCam;


		if (bypassDelta) {
			deltaModIgnorers.add(o);
		}
	}

	public function softFollowPlayer() {
		baseTerrainCam.setScrollBoundsRect(0, 0, softFocusBounds.width, softFocusBounds.height);
		baseTerrainCam.follow(player, FlxCameraFollowStyle.PLATFORMER, .5);
	}

	public function hardFollowPlayer(lerp:Float) {
		baseTerrainCam.setScrollBounds(null, null, null, null);
		baseTerrainCam.follow(player, FlxCameraFollowStyle.LOCKON, lerp);
	}

	public function playerDied() {
		player.beginDie();
		FlxTween.tween(this, {deltaMod: deathDeltaMod}, 0.2, {
			onComplete: (tween1) -> {
				new FlxTimer().start(.7, (timer) -> {
					player.kill();
					DeathParticles.create(player.body.x, player.body.y, !player.grounded, [EMPTY, RED, BLUE]);
					FlxG.cameras.flash(0.5);
					new FlxTimer().start(1, (timer2) -> {
						FlxTween.tween(this, {deltaMod: 1}, 1, {
							onComplete: (tween2) -> {
								new FlxTimer().start(1.5, (timer3) -> {
									resetLevel();
								});
							}
						});
					});
				});
			}
		});
		
	}

	override public function update(elapsed:Float) {
		var originalDelta = elapsed;
		elapsed *= deltaMod;
		super.update(elapsed);

		for (o in pendingObjects) {
			o.add_to_group(objects);
		}
		pendingObjects = [];

		for (l in pendingLasers) {
			l.add_to_group(lasers);
		}
		pendingLasers = [];

		if (deltaMod < 1) {
			deltaModIgnorers.update(originalDelta * (1 - deltaMod));
		}

		for (i in 0...FlxG.cameras.list.length) {
			DebugDraw.ME.drawCameraCircle(FlxG.cameras.list[i], 10, 10 * i, 5, null, FlxColor.WHITE);

		}

		// on initial spawn, player is in the wrong place
		if (deathGraceFrames > 0) {
			deathGraceFrames--;
		} else {
			checkPlayerOffScreen();
		}

		alignCameras();
	}

	var deathGraceFrames = 1;

	var boundAdjust = 10;
	var playerBounds:AABB = null;
	function checkPlayerOffScreen() {
		if (!player.inControl) {
			return;
		}
		trace(playerBounds);
		playerBounds = player.body.bounds(playerBounds);
		trace(playerBounds);
		trace(objectCam.getViewMarginRect());
		if (!camSeesWorldPoint(objectCam, playerBounds.min_x - boundAdjust, playerBounds.min_y - boundAdjust) &&
			!camSeesWorldPoint(objectCam, playerBounds.max_x + boundAdjust, playerBounds.min_y - boundAdjust) &&
			!camSeesWorldPoint(objectCam, playerBounds.max_x + boundAdjust, playerBounds.max_y + boundAdjust) &&
			!camSeesWorldPoint(objectCam, playerBounds.min_x - boundAdjust, playerBounds.max_y + boundAdjust)) {
				playerDied();
		}
	}

	var tmpScreenPoint = FlxPoint.get();
	function camSeesWorldPoint(cam:FlxCamera, x:Float, y:Float):Bool {
		tmpScreenPoint = objectCam.project(FlxPoint.weak(x, y));
		return objectCam.containsPoint(tmpScreenPoint);
	}

	function alignCameras() {
		for (c in colorCams) {
			c.scroll.copyFrom(baseTerrainCam.scroll);
		}

		dbgCam.scroll.copyFrom(baseTerrainCam.scroll);
		objectCam.scroll.copyFrom(baseTerrainCam.scroll);
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
