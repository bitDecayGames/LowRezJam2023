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

using states.FlxStateExt;
using echo.FlxEcho;

class PlayState extends FlxTransitionableState {
	public static var ME:PlayState;

	public static var backgroundColor = FlxColor.GRAY.getDarkened(0.8);

	var lastLevel:String;
	var lastSpawnEntity:String;

	public var player:Player;

	public var mainCam:FlxCamera;
	public var colorCams:Map<Color, FlxCamera> = [];
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

		FlxEcho.init({width: FlxG.width, height: FlxG.height, gravity_y: 24 * Constants.BLOCK_SIZE});

		#if debug
		FlxEcho.draw_debug = true;
		#end

		mainCam = FlxG.camera;

		mainCam.bgColor = backgroundColor;

		setupColorCameras();

		dbgCam = new FlxCamera();
		dbgCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(dbgCam, false);

		for (c in FlxG.cameras.list) {
			FlxG.cameras.setDefaultDrawTarget(c, false);
		}

		FlxG.cameras.setDefaultDrawTarget(mainCam, true);

		// TODO: These don't seem to be rendering in the order we define them...
		

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
		mainCam.setFilters( [new ShaderFilter(pixelShader)] ); 

		for (color in Color.asList()) {
			var colorCam = new FlxCamera();
			// colorCam.visible = false;
			var shader = new PixelateShader(color);
			colorCam.setFilters( [new ShaderFilter(shader)]);
			colorCam.bgColor = FlxColor.TRANSPARENT;
			colorCams.set(color, colorCam);
			FlxG.cameras.add(colorCam, true);
		};
	}

	function setCamera(ccs:ColorCollideSprite) {
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
		add(objects);

		var level = new levels.ldtk.Level(levelID);

		terrainGroup.add(level.terrainGfx);

		softFocusBounds = FlxRect.get(0, 0, level.bounds.width, level.bounds.height);
		FlxEcho.instance.world.set(0, 0, level.bounds.width, level.bounds.height);

		TileTypes.buildTiles(level, objects);
		
		for (o in level.objects) {
			o.add_to_group(objects);
		}

		trace('scanning ${objects.members.length}');
		for (o in objects.members) {
			if (o != null && o is ColorCollideSprite) {
				var ccs:ColorCollideSprite = cast o;
				setCamera(ccs);
			}
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

		mainCam.focusOn(player.getGraphicMidpoint());
		dbgCam.scroll.copyFrom(mainCam.scroll);

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
		setCamera(laser);
	}

	public function addParticle(o:FlxBasic, bypassDelta:Bool = false) {
		particles.add(o);

		if (bypassDelta) {
			deltaModIgnorers.add(o);
		}
	}

	public function softFollowPlayer() {
		mainCam.setScrollBoundsRect(0, 0, softFocusBounds.width, softFocusBounds.height);
		mainCam.follow(player, FlxCameraFollowStyle.PLATFORMER, .5);
	}

	public function hardFollowPlayer(lerp:Float) {
		mainCam.setScrollBounds(null, null, null, null);
		mainCam.follow(player, FlxCameraFollowStyle.LOCKON, lerp);
	}

	public function playerDied() {
		player.beginDie();
		// TODO: Tie in player animation for timing somehow
		FlxTween.tween(this, {deltaMod: deathDeltaMod}, 0.2, {
			onComplete: (tween1) -> {
				new FlxTimer().start(.7, (timer) -> {
					player.kill();
					DeathParticles.create(player.body.x, player.body.y, !player.grounded, [EMPTY, RED, BLUE]);
					mainCam.flash(0.5);
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

		DebugDraw.ME.drawCameraCircle(FlxG.width/2, FlxG.height/2, 2);

		alignCameras();
	}

	function alignCameras() {
		for (c in colorCams) {
			c.scroll.copyFrom(mainCam.scroll);
		}

		dbgCam.scroll.copyFrom(mainCam.scroll);
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
