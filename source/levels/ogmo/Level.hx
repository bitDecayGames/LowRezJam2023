package levels.ogmo;

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

	@:access(flixel.addons.editors.ogmo.FlxOgmo3Loader)
	public function new(level:String) {
		var loader = new FlxOgmo3Loader(AssetPaths.lowrez2023__ogmo, level);
		layer = loader.loadTilemap(AssetPaths.testTiles__png, "terrain");
		// loader.loadGridMap("collisions");
		// loader.layers
		collisionsRaw = layer.getData();
		collisionLayerSize = FlxPoint.get(layer.widthInTiles, layer.heightInTiles);


		objects = new FlxTypedGroup<FlxObject>();

		loader.loadEntities((entityData) -> {
			var obj:FlxObject = null;
			switch (entityData.name) {
				case "spawn":
					obj = new Player(entityData.x, entityData.y);
				default:
					QuickLog.error('Entity \'${entityData.name}\' is not supported, add parsing to ${Type.getClassName(Type.getClass(this))}');
			}
			objects.add(obj);
		}, "entities");
	}
}
