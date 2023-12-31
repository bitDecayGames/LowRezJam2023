package levels.ldtk;

import states.PlayState;
import entities.enemy.PermaLaser;
import entities.enemy.BaseLaser.BaseLaserOptions;
import entities.enemy.BaseLaser.LaserRailOptions;
import collision.ColorCollideSprite;
import entities.camera.CameraTransitionZone;
import entities.enemy.LaserStationary;
import helpers.CardinalMaker;
import bitdecay.flixel.spacial.Cardinal;
import collision.Color;
import progress.Collected;
import entities.ColorUpgrade;
import entities.Transition;
import entities.enemy.LaserTurret;
import flixel.math.FlxRect;
import entities.enemy.LaserRail;
import entities.Player;
import flixel.effects.particles.FlxEmitter;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;

class Level {
	private static inline var WORLD_ID = "48a599b1-1460-11ee-8f1d-bf5d483c5ed2";
	public static var project = new LDTKProject();
	
	// in case we need something specific
	public var raw:LDTKProject_Level;

	public var bounds = FlxRect.get();
	public var terrainGfx = new FlxSpriteGroup();
	public var rawFineTerrainInts = new Array<Int>();
	public var rawFineTerrainTilesWide = 0;
	public var rawFineTerrainTilesTall = 0;

	public var rawCoarseTerrainInts = new Array<Int>();
	public var rawCoarseTerrainTilesWide = 0;
	public var rawCoarseTerrainTilesTall = 0;

	public var rawFineTerrainLayer:levels.ldtk.LDTKProject.Layer_Terrain_fine;
	public var rawCoarseTerrainLayer:levels.ldtk.LDTKProject.Layer_Terrain_coarse;

	public var objects = new FlxTypedGroup<FlxObject>();
	public var beams = new FlxTypedGroup<FlxObject>();
	public var emitters = new Array<FlxEmitter>();
	public var playerSpawn:Entity_Spawn;

	public var camZones:Map<String, FlxRect>;
	public var camTransitionZones:Array<CameraTransitionZone>;

	public function new(nameOrIID:String) {
		var level = project.all_worlds.Default.getLevel(nameOrIID);
		raw = level;

		bounds.width = level.pxWid;
		bounds.height = level.pxHei;
		rawFineTerrainLayer = level.l_Terrain_fine;
		rawCoarseTerrainLayer = level.l_Terrain_coarse;
		terrainGfx = level.l_Terrain_fine.render();
		level.l_Terrain_coarse.render(terrainGfx);
		rawFineTerrainInts = new Array<Int>();
		rawFineTerrainTilesWide = level.l_Terrain_fine.cWid;
		rawFineTerrainTilesTall = level.l_Terrain_fine.cHei;
		for (ch in 0...level.l_Terrain_fine.cHei) {
			for (cw in 0...level.l_Terrain_fine.cWid) {
				if (level.l_Terrain_fine.hasAnyTileAt(cw, ch)) {
					var tileStack = level.l_Terrain_fine.getTileStackAt(cw, ch);
					rawFineTerrainInts.push(tileStack[0].tileId);
				} else {
					rawFineTerrainInts.push(0);
				}
			}
		}

		rawCoarseTerrainInts = new Array<Int>();
		rawCoarseTerrainTilesWide = level.l_Terrain_coarse.cWid;
		rawCoarseTerrainTilesTall = level.l_Terrain_coarse.cHei;
		for (ch in 0...level.l_Terrain_coarse.cHei) {
			for (cw in 0...level.l_Terrain_coarse.cWid) {
				if (level.l_Terrain_coarse.hasAnyTileAt(cw, ch)) {
					var tileStack = level.l_Terrain_coarse.getTileStackAt(cw, ch);
					rawCoarseTerrainInts.push(tileStack[0].tileId);
				} else {
					rawCoarseTerrainInts.push(0);
				}
			}
		}

		parseLaserRails(level);
		parseLaserTurrets(level);
		parseLaserStationary(level);
		parseCameraAreas(level);
		parseCameraTransitions(level);

		for (door in level.l_Objects.all_Door) {
			var d = new Transition(door);
			objects.add(d);
		}

		for (u in level.l_Objects.all_Color_upgrade) {
			if (Collected.has(Color.fromEnum(u.f_Color))) {
				// they already have collected this
				continue;
			}
			var upgrader = new ColorUpgrade(u);
			objects.add(upgrader);
			emitters.push(upgrader.particle);
		}
	}

	function parseLaserRails(level:LDTKProject_Level) {
		var laserOps:Array<LaserRailOptions> = [];
		for (l in level.l_Objects.all_Laser_rail_up) {
			laserOps.push({
				spawnX: l.pixelX,
				spawnY: l.pixelY,
				color: Color.fromEnum(l.f_Color),
				dir: Cardinal.N,
				path: [for (point in l.f_path) {
					FlxPoint.get(point.cx * level.l_Objects.gridSize, point.cy * level.l_Objects.gridSize);
				}],
				pauseOnFire: l.f_Pause_on_fire,
				rest: l.f_Rest,
				delay: l.f_Initial_delay,
				shootOnNode: l.f_Shoot_on_node,
				laserTime: l.f_Laser_time,
				muted: false,
			});
		}
		for (l in level.l_Objects.all_Laser_rail_down) {
			laserOps.push({
				spawnX: l.pixelX,
				spawnY: l.pixelY,
				color: Color.fromEnum(l.f_Color),
				dir: Cardinal.S,
				path: [for (point in l.f_path) {
					FlxPoint.get(point.cx * level.l_Objects.gridSize, point.cy * level.l_Objects.gridSize);
				}],
				pauseOnFire: l.f_Pause_on_fire,
				rest: l.f_Rest,
				delay: l.f_Initial_delay,
				shootOnNode: l.f_Shoot_on_node,
				laserTime: l.f_Laser_time,
				muted: false,
			});
		}
		for (l in level.l_Objects.all_Laser_rail_left) {
			laserOps.push({
				spawnX: l.pixelX,
				spawnY: l.pixelY,
				color: Color.fromEnum(l.f_Color),
				dir: Cardinal.W,
				path: [for (point in l.f_path) {
					FlxPoint.get(point.cx * level.l_Objects.gridSize, point.cy * level.l_Objects.gridSize);
				}],
				pauseOnFire: l.f_Pause_on_fire,
				rest: l.f_Rest,
				delay: l.f_Initial_delay,
				shootOnNode: l.f_Shoot_on_node,
				laserTime: l.f_Laser_time,
				muted: false,

			});
		}
		for (l in level.l_Objects.all_Laser_rail_right) {
			laserOps.push({
				spawnX: l.pixelX,
				spawnY: l.pixelY,
				color: Color.fromEnum(l.f_Color),
				dir: Cardinal.E,
				path: [for (point in l.f_path) {
					FlxPoint.get(point.cx * level.l_Objects.gridSize, point.cy * level.l_Objects.gridSize);
				}],
				pauseOnFire: l.f_Pause_on_fire,
				rest: l.f_Rest,
				delay: l.f_Initial_delay,
				shootOnNode: l.f_Shoot_on_node,
				laserTime: l.f_Laser_time,
				muted: false,
			});
		}

		for (l_config in laserOps) {
			var laser = new LaserRail(l_config);
			objects.add(laser);
			objects.add(laser.chargeParticle);
			beams.add(laser.beam);
			emitters.push(laser.emitter);
		}
	}

	function parseLaserTurrets(level:LDTKProject_Level) {
		for (laser_turret in level.l_Objects.all_Laser_turret) {
			var spawnPoint = FlxPoint.get(laser_turret.pixelX, laser_turret.pixelY);
			var adjust = FlxPoint.get(-16, -16);
			spawnPoint.addPoint(adjust);
			var path = new Array<FlxPoint>();
			path.push(spawnPoint);
			var laser = new LaserTurret({
				spawnX: spawnPoint.x,
				spawnY: spawnPoint.y,
				color: Color.fromEnum(laser_turret.f_Color),
				dir: N,
				rest: laser_turret.f_Rest,
				delay: laser_turret.f_Initial_delay,
				laserTime: laser_turret.f_Laser_time,
				muted: false,
			});
			objects.add(laser);
			objects.add(laser.chargeParticle);
			beams.add(laser.beam);
			emitters.push(laser.emitter);
		}
	}

	function parseLaserStationary(level:LDTKProject_Level) {
		var laserOps:Array<BaseLaserOptions> = [];

		for (l in level.l_Objects.all_Laser_mount_up) {
			laserOps.push({
				spawnX: l.pixelX,
				spawnY: l.pixelY,
				color: Color.fromEnum(l.f_Color),
				dir: Cardinal.N,
				rest: l.f_Rest,
				laserTime: l.f_Laser_time,
				delay: l.f_Initial_delay,
				muted: l.f_Mute,
			});
		}
		for (l in level.l_Objects.all_Laser_mount_down) {
			laserOps.push({
				spawnX: l.pixelX,
				spawnY: l.pixelY,
				color: Color.fromEnum(l.f_Color),
				dir: Cardinal.S,
				rest: l.f_Rest,
				laserTime: l.f_Laser_time,
				delay: l.f_Initial_delay,
				muted: l.f_Mute,
			});
		}
		for (l in level.l_Objects.all_Laser_mount_left) {
			laserOps.push({
				spawnX: l.pixelX,
				spawnY: l.pixelY,
				color: Color.fromEnum(l.f_Color),
				dir: Cardinal.W,
				rest: l.f_Rest,
				laserTime: l.f_Laser_time,
				delay: l.f_Initial_delay,
				muted: l.f_Mute,
			});
		}
		for (l in level.l_Objects.all_Laser_mount_right) {
			laserOps.push({
				spawnX: l.pixelX,
				spawnY: l.pixelY,
				color: Color.fromEnum(l.f_Color),
				dir: Cardinal.E,
				rest: l.f_Rest,
				laserTime: l.f_Laser_time,
				delay: l.f_Initial_delay,
				muted: l.f_Mute,
			});
		}

		for (l_config in laserOps) {
			var laser = new LaserStationary(l_config);
			objects.add(laser);
			objects.add(laser.chargeParticle);
			beams.add(laser.beam);
			emitters.push(laser.emitter);
		}

		for (l in level.l_Objects.all_Perma_laser) {
			var laser = new PermaLaser(l.pixelX, l.pixelY, CardinalMaker.fromString(l.f_Direction.getName()), Color.fromEnum(l.f_Color));
			objects.add(laser);
		}
	}

	function parseCameraAreas(level:LDTKProject_Level) {
		camZones = new Map<String, FlxRect>();
		for (guide in level.l_Objects.all_Camera_guide) {
			camZones.set(guide.iid, FlxRect.get(guide.pixelX, guide.pixelY, guide.width, guide.height));
		}
	}

	function parseCameraTransitions(level:LDTKProject_Level) {
		camTransitionZones = new Array<CameraTransitionZone>();
		for (zone in level.l_Objects.all_Camera_transition) {
			var transArea = FlxRect.get(zone.pixelX, zone.pixelY, zone.width, zone.height);
			var camTrigger = new CameraTransitionZone(transArea);
			for (i in 0...zone.f_dir.length) {
				camTrigger.addGuideTrigger(CardinalMaker.fromString(zone.f_dir[i].getName()), camZones.get(zone.f_areas[i].entityIid));
			}
			camTransitionZones.push(camTrigger);
		}
	}
}