package levels.ldtk;

import entities.LaserTurret;
import flixel.math.FlxRect;
import entities.LaserRail;
import entities.Player;
import flixel.effects.particles.FlxEmitter;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;

class Level {
	private static inline var WORLD_ID = "48a599b1-1460-11ee-8f1d-bf5d483c5ed2";
	var project = new LDTKProject();

	public var bounds = FlxRect.get();
	public var terrainGfx = new FlxSpriteGroup();
	public var rawTerrainInts = new Array<Int>();
	public var rawTerrainTilesWide = 0;
	public var rawTerrainTilesTall = 0;

	public var rawTerrainLayer:levels.ldtk.LDTKProject.Layer_Terrain;

	public var objects = new FlxTypedGroup<FlxObject>();
	public var emitters = new Array<FlxEmitter>();
	public var player:Player;

	public function new(name:String) {
		var level = project.all_worlds.Default.getLevel(name);
		bounds.width = level.pxWid;
		bounds.height = level.pxHei;
		rawTerrainLayer = level.l_Terrain;
		terrainGfx = level.l_Terrain.render();
		rawTerrainInts = new Array<Int>();
		rawTerrainTilesWide = level.l_Terrain.cWid;
		rawTerrainTilesTall = level.l_Terrain.cHei;
		for (ch in 0...level.l_Terrain.cHei) {
			for (cw in 0...level.l_Terrain.cWid) {
				if (level.l_Terrain.hasAnyTileAt(cw, ch)) {
					var tileStack = level.l_Terrain.getTileStackAt(cw, ch);
					rawTerrainInts.push(tileStack[0].tileId);
				} else {
					rawTerrainInts.push(0);
				}
			}
		}

		var playerSpawn = level.l_Objects.all_Spawn[0];
		player = new Player(playerSpawn.pixelX, playerSpawn.pixelY);

		for (laser_rail in level.l_Objects.all_Laser_rail) {
			var spawnPoint = FlxPoint.get(laser_rail.pixelX, laser_rail.pixelY);
			// TODO: Adjust these based on the rotation of the entity
			var adjust = FlxPoint.get(16, 16).rotateByDegrees(0);
			spawnPoint.addPoint(adjust);
			var path = new Array<FlxPoint>();
			path.push(spawnPoint);
			for (node in laser_rail.f_path) {
				path.push(FlxPoint.get(node.cx * level.l_Objects.gridSize, node.cy * level.l_Objects.gridSize).addPoint(adjust));
			}
			var laser = new LaserRail(spawnPoint.x, spawnPoint.y, Color.fromStr(laser_rail.f_Color.getName()), path);
			objects.add(laser);
			emitters.push(laser.emitter);
		}

		for (laser_turret in level.l_Objects.all_Laser_turret) {
			var spawnPoint = FlxPoint.get(laser_turret.pixelX, laser_turret.pixelY);
				var adjust = FlxPoint.get(16, 16);
				spawnPoint.addPoint(adjust);
				var path = new Array<FlxPoint>();
				path.push(spawnPoint);
				var laser = new LaserTurret(spawnPoint.x, spawnPoint.y, Color.fromStr(laser_turret.f_Color.getName()));
				objects.add(laser);
				emitters.push(laser.emitter);
		}
	}
}