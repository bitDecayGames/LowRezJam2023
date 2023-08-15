package states;

import flixel.FlxSprite;
import ldtk.Level;
import states.substate.UpgradeCutscene;
import openfl.filters.ShaderFilter;
import shaders.PixelateShader;
import flixel.util.FlxTimer;
import entities.particles.DeathParticles;
import flixel.tweens.FlxTween;
import flixel.FlxBasic;
import flixel.math.FlxRect;
import entities.Transition;
import collision.TileTypes;
import progress.Collected;
import helpers.CardinalMaker;
import entities.enemy.LaserBeam;
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
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.addons.transition.FlxTransitionableState;
import signals.Lifecycle;
import entities.Player;
import flixel.FlxG;
import bitdecay.flixel.debug.DebugDraw;

using bitdecay.flixel.extensions.FlxCameraExt;
using states.FlxStateExt;
using echo.FlxEcho;

class PlayState extends FlxTransitionableState {
	public static var ME:PlayState;

	public static var backgroundColor = FlxColor.GRAY.getDarkened(0.8);
	
	public var deltaModTimerMgr:FlxTimerManager = new FlxTimerManager();

	public var playerDying:Bool = false;

	var lastLevel:String;
	var lastSpawnEntity:String;

	public var player:Player;

	public var baseTerrainCam:FlxCamera;
	public var colorCams:Map<Color, FlxCamera> = [];
	public var objectCam:FlxCamera;
	public var dbgCam:FlxCamera;

	var shaders:Array<PixelateShader> = [];
	
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

	public var levelTime = 0.0;

	var resetQueued = false;

	public function new() {
		super();
		ME = this;
	}

	@:access(flixel.FlxState)
	override public function create() {
		super.create();

		Lifecycle.startup.dispatch();

		FmodManager.PlaySong(FmodSongs.Song1);

		FmodManager.SetEventParameterOnSong("volume", 1);

		// main will do this, but if we are dev'ing and going straight to the play screen, it may not be done yet
		Collected.initialize();

		Collected.setMusicParameters();

		persistentUpdate = true;

		baseTerrainCam = FlxG.camera;
		baseTerrainCam.bgColor = backgroundColor;

		setupColorCameras();

		objectCam = makeShaderCamera(EMPTY);
		FlxG.cameras.add(objectCam, false);

		// XXX: need the substate to use the right cameras... but it's not set yet, so we go to this
		// variable to get it
		if (_requestedSubState != null) {
			_requestedSubState.camera = PlayState.ME.objectCam;
		}

		// Set up echo last so it draws on top of all of our cameras
		FlxEcho.init({
			width: FlxG.width,
			height: FlxG.height, 
			gravity_y: 24 * Constants.BLOCK_SIZE,
			iterations: 16,
		});
		FlxG.plugins.remove(FlxEcho.instance);

		#if debug_echo
		FlxEcho.draw_debug = true;
		#end
		
		dbgCam = new FlxCamera();
		dbgCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(dbgCam, false);

		add(terrainGroup);
		add(objects);
		add(playerGroup);
		add(lasers);
		add(particles);

		#if dev_spawn
		var devSpawnLevel = levels.ldtk.Level.project.all_worlds.Default.levels.filter((l) -> return l.l_Objects.all_Dev_spawn.length > 0);
		if (devSpawnLevel.length > 0) {
			loadLevel(devSpawnLevel[0].iid);
		} else {
			QuickLog.error('no dev spawn found');
			loadLevel("Level_23");
		}
		#else
		var checkpointRoom = Collected.getCheckpointLevel();
		var checkpointEntity = Collected.getCheckpointEntity();
		if (checkpointRoom != null && checkpointEntity != null) {
			loadLevel(checkpointRoom, checkpointEntity);
		} else {
			var spawnLevel = levels.ldtk.Level.project.all_worlds.Default.levels.filter((l) -> return l.l_Objects.all_Spawn.length > 0);
			if (spawnLevel.length > 0) {
				loadLevel(spawnLevel[0].iid);
			} else {
				QuickLog.error('no dev spawn found');
				loadLevel("Level_23");
			}
		}
		#end
	}

	override function draw() {
		FlxEcho.instance.draw();
		super.draw();
	}

	function setupColorCameras() {
		var pixelShader = new PixelateShader(Color.EMPTY);
		shaders.push(pixelShader);
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
		shaders.push(shader);
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
		if (resetQueued) {
			return;
		}

		// we don't want to reset the level multiple times in a row as it causes
		// errors
		resetQueued = true;
		loadLevel(lastLevel, lastSpawnEntity);
	}

	@:access(echo.FlxEcho)
	@:access(ldtk.Layer_Tiles)
	public function loadLevel(levelID:String, ?entityID:String) {
		lastLevel = levelID;
		lastSpawnEntity = entityID;

		Collected.addTime(levelTime);
		levelTime = 0;

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

		if(level.raw.identifier == "Level_34") {
			Collected.enableSafeReturn();
		}

		softFocusBounds = FlxRect.get(0, 0, level.bounds.width, level.bounds.height);
		baseTerrainCam.setScrollBoundsRect(0, 0, level.bounds.width, level.bounds.height);

		FlxEcho.instance.world.set(0, 0, level.bounds.width, level.bounds.height);

		var tileObjs = TileTypes.buildTiles(level);
		for (t in tileObjs) {
			t.add_to_group(objects);
			t.add_to_group(terrainGroup);
			setCamera(t);
		}

		if (level.raw.identifier == "Level_4" && Collected.getSafeReturn()) {
			// 48, 448
			var s = new FlxSprite(48, 448);
			s.frame = level.raw.l_Terrain_fine.untypedTileset.getFrame(42).copyTo();
			s.add_body({
				x: 48,
				y: 448,
				mass: STATIC,
				shape: {
					type: RECT,
					width: 16,
					height: 16,
					offset_x: 8,
					offset_y: 8,
				}
			});
			FlxEcho.update_body_object(s.get_body());
			s.add_to_group(objects);
			s.add_to_group(terrainGroup);
			setCamera(s);
		}
		
		for (o in level.objects) {
			o.add_to_group(objects);
			o.camera = objectCam;
		}

		for (o in level.beams) {
			o.add_to_group(lasers);
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
						break;
					}
				}
			}
			var spawnDir = CardinalMaker.fromString(spawn.f_access_dir.getName());
			spawnPoint.set(spawn.pixelX, spawn.pixelY);
			// TODO: find a better way to calculate this offset
			spawnPoint.addPoint(spawnDir.asVector().scale(16));

			FlxEcho.updates = false;
			FlxEcho.instance.active = false;
			extraSpawnLogic = () -> {
				player.transitionWalk(true, spawnDir, () -> {
					FlxEcho.updates = true;
					FlxEcho.instance.active = true;
					t.close();
				});
			}
		#if dev_spawn
		} else if (level.raw.l_Objects.all_Dev_spawn.length > 0) {
			var devSpawn = level.raw.l_Objects.all_Dev_spawn[0];
			spawnPoint.set(devSpawn.pixelX, devSpawn.pixelY);
		#else
		} else if (level.raw.l_Objects.all_Spawn.length > 0) {
			var rawSpawn = level.raw.l_Objects.all_Spawn[0];
			spawnPoint.set(rawSpawn.pixelX, rawSpawn.pixelY);
		#end
		} else {
			QuickLog.critical('no spawn found, and no entity provided. Cannot spawn player');
		}

		player = new Player(spawnPoint.x, spawnPoint.y);
		player.add_to_group(playerGroup);
		player.camera = objectCam;
		// deltaModIgnorers.add(player);
		if (extraSpawnLogic != null) {
			extraSpawnLogic();
		}


		for (_ => zone in level.camZones) {
			if (zone.containsPoint(spawnPoint)) {
				setCameraBounds(zone);
			}
		}

		for (camTransition in level.camTransitionZones) {
			camTransition.add_to_group(objects);
		}

		// baseTerrainCam.focusOn(player.getPosition());
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
			stay: (a, b, o) -> {
				if (Std.isOfType(a.object, ColorCollideSprite)) {
					cast(a.object, ColorCollideSprite).handleStay(b, o);
				}
				if (Std.isOfType(b.object, ColorCollideSprite)) {
					cast(b.object, ColorCollideSprite).handleStay(a, o);
				}
			},
		});

		FlxEcho.listen(playerGroup, objects, {
			condition: Collide.colorBodiesInteract,
			correction_threshold: .025, // not sure if this actually helps, but it seems to result in less snagging
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

		// FlxEcho.instance.update(0.01);
		// update(0.01);
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

	public function setCameraBounds(bounds:FlxRect) {
		// baseTerrainCam.setScrollBounds(bounds.x, bounds.y, bounds.width, bounds.height);
		baseTerrainCam.setScrollBoundsRect(bounds.x, bounds.y, bounds.width, bounds.height);
	}

	public function softFollowPlayer() {
		// baseTerrainCam.setScrollBoundsRect(0, 0, softFocusBounds.width, softFocusBounds.height);
		baseTerrainCam.follow(player, FlxCameraFollowStyle.PLATFORMER, 1);
	}

	public function hardFollowPlayer(lerp:Float) {
		// baseTerrainCam.setScrollBounds(null, null, null, null);
		baseTerrainCam.follow(player, FlxCameraFollowStyle.LOCKON, 1);
	}

	public function freezeCamera() {
		baseTerrainCam.follow(null);
	}

	public function playerDied() {
		player.beginDie();
		FmodManager.SetEventParameterOnSong("LowPass", 1);
		// freeze time
		deltaMod = 0;

		// wait
		new FlxTimer().start(0.5, (t) -> {
			// then bring it back up to slowmo and finish animating the player
			player.finishDeath();
			FlxTween.tween(this, {deltaMod: deathDeltaMod}, .1, {
				onComplete: (tween1) -> {
					new FlxTimer(PlayState.ME.deltaModTimerMgr).start(.075, (timer) -> {
						FmodManager.PlaySoundOneShot(FmodSFX.PlayerDieBurst2);
						player.kill();
						DeathParticles.create(player.body.x, player.body.y, !player.grounded, Collected.unlockedColors());
						FlxG.cameras.flash(0.5);
						new FlxTimer().start(.5, (timer2) -> {
							FlxTween.tween(this, {deltaMod: 1}, .5, {
								onComplete: (tween2) -> {
									new FlxTimer(PlayState.ME.deltaModTimerMgr).start(1, (timer3) -> {
										FmodManager.SetEventParameterOnSong("LowPass", 0);
										resetLevel();
									});
								}
							});
						});
					});
				}
			});
		});
	}

	override public function update(elapsed:Float) {

		#if debug
		if(FlxG.keys.justPressed.LBRACKET) {
			FlxG.state.openSubState(new UpgradeCutscene(false, FlxPoint.get(FlxG.width/2, FlxG.height/2), Color.BLUE, () -> {
				
			}));
		}

		if(FlxG.keys.justPressed.RBRACKET) {
			FlxG.switchState(new CreditsState());
		}

		if (FlxG.keys.justPressed.N) {
			Collected.enableSafeReturn();
		}
		#end

		resetQueued = false;


		#if debug_time
		FlxG.watch.addQuick('deltaMod: ', deltaMod);
		#end
		var originalDelta = elapsed;
		elapsed *= deltaMod;
		deltaModTimerMgr.update(elapsed);

		// we do this here so our modified elapsed time is used by the physics
		if (FlxEcho.instance.active) {
			FlxEcho.instance.update(elapsed);
		}

		super.update(elapsed);

		if (player.inControl) {
			levelTime += elapsed;
		}

		for (o in pendingObjects) {
			o.add_to_group(objects);
		}
		pendingObjects = [];

		for (l in pendingLasers) {
			l.add_to_group(lasers);
		}
		pendingLasers = [];

		if (deltaMod < 1) {
			deltaModIgnorers.update(originalDelta - elapsed);
		}

		alignCameras();

		for (s in shaders) {
			s.update(elapsed);
		}

		#if debug_camera
		FlxG.watch.addQuick('camScroll: ', ${baseTerrainCam.scroll});
		#end
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
