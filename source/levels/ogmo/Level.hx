package levels.ogmo;

import collision.Color;
import flixel.effects.particles.FlxEmitter;
import entities.LaserTurret;
import entities.LaserRail;
import entities.Player;
import flixel.math.FlxPoint;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.addons.editors.ogmo.FlxOgmo3Loader;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;

/**
 * Template for loading an Ogmo level file
**/
class Level {
	public var layer:FlxTilemap;
	public var collisionsRaw:Array<Int>;
	public var collisionLayerSize:FlxPoint;

	public var objects:FlxTypedGroup<FlxObject>;
	public var emitters:Array<FlxEmitter>;
	public var player:Player;

	@:access(flixel.addons.editors.ogmo.FlxOgmo3Loader)
	public function new(level:String) {
		var loader = new FlxOgmo3Loader(AssetPaths.lowrez2023__ogmo, level);
		layer = loader.loadTilemap(AssetPaths.testTiles__png, "terrain");
		// loader.loadGridMap("collisions");
		// loader.layers
		collisionsRaw = layer.getData();
		collisionLayerSize = FlxPoint.get(layer.widthInTiles, layer.heightInTiles);


		objects = new FlxTypedGroup<FlxObject>();
		emitters = new Array<FlxEmitter>();

		loader.loadEntities((entityData) -> {
			var obj:FlxObject = null;
			switch (entityData.name) {
				case "spawn":
					player = new Player(entityData.x, entityData.y);
				case "laser_turret":
					// TODO: Parse this from the map
					var laser = new LaserTurret(entityData.x, entityData.y, Color.fromStr(entityData.values.color));
					objects.add(laser);
					emitters.push(laser.emitter);
				case "laser_rail":
					var spawnPoint = FlxPoint.get(entityData.x, entityData.y);
					var adjust = FlxPoint.get(16, 16).rotateByDegrees(entityData.rotation);
					spawnPoint.addPoint(adjust);
					var path = new Array<FlxPoint>();
					path.push(spawnPoint);
					for (node in entityData.nodes) {
						path.push(FlxPoint.get(node.x, node.y).addPoint(adjust));
					}
					var laser = new LaserRail(spawnPoint.x, spawnPoint.y, Color.fromStr(entityData.values.color), path);
					objects.add(laser);
					emitters.push(laser.emitter);
				default:
					QuickLog.error('Entity \'${entityData.name}\' is not supported, add parsing to ${Type.getClassName(Type.getClass(this))}');
			}
		}, "entities");
	}
}
