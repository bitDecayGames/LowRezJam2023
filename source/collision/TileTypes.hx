package collision;

import flixel.FlxObject;
import flixel.FlxSprite;
import levels.ldtk.Level;
import flixel.group.FlxGroup;
import echo.Body;
import ldtk.Layer_Tiles;

using echo.FlxEcho;

// basic mapping of tile index to what color filter they should have applied
class TileTypes {
	public static var mapping = [
		1 => Color.EMPTY,
		2 => Color.BLUE,
		3 => Color.YELLOW,
		4 => Color.RED,
		5 => Color.GREEN,
		6 => Color.PURPLE,
		7 => Color.ORANGE,
		8 => Color.ALL,
	];


	public static function buildTiles(level:Level):Array<FlxObject> {
		var objs = buildForLayer(level.raw.l_Terrain_coarse, level.raw.l_TerrainColor);
		return objs.concat(buildForLayer(level.raw.l_Terrain_fine, level.raw.l_TerrainColor));
	}

	// This is taken from the ldtk codebase so that we can augment it to add color and attach echo bodies
	@:access(ldtk.Layer_Tiles)
	@:access(echo.FlxEcho)
	static function buildForLayer(layer:Layer_Tiles, colorLayer:Layer_TerrainColor):Array<FlxObject> {
		var tiles:Array<FlxObject> = [];
		for( cy in 0...layer.cHei ) {
			for( cx in 0...layer.cWid ) {
				if( layer.hasAnyTileAt(cx,cy) ) {
					for( tile in layer.getTileStackAt(cx,cy) ) {
						if (tile.tileId == 0) {
							continue;
						}
	
						var xPix = cx*layer.gridSize + layer.pxTotalOffsetX;
						var yPix = cy*layer.gridSize + layer.pxTotalOffsetY;
						var b = new Body({
							x: xPix,
							y: yPix,
							mass: STATIC,
							shape: {
								type: RECT,
								width: layer.gridSize,
								height: layer.gridSize,
								offset_x: layer.gridSize * 0.5,
								offset_y: layer.gridSize * 0.5
							}
						});
						
						var color = TileTypes.getColorFromTile(cx, cy, layer.gridSize, colorLayer);
	
						var s:FlxSprite;
						if (color != EMPTY) {
							s = new ColorCollideSprite(xPix, yPix, color);
						} else {
							s = new FlxSprite(xPix, yPix);
						}

						s.flipX = tile.flipBits & 1 != 0;
						s.flipY = tile.flipBits & 2 != 0;
						s.frame = layer.untypedTileset.getFrame(tile.tileId).copyTo();
						s.width = layer.gridSize;
						s.height = layer.gridSize;
						s.set_body(b);
						b.update_body_object();
						tiles.push(s);
					}
				}
			}
		}
		
		return tiles;
	}

	public static function getColorFromTile(cX:Int, cY:Int, gridSize:Int, colors:Layer_TerrainColor):Color {
		var scale:Int = Std.int(gridSize / colors.gridSize);
		var colorInt = colors.getInt(cX * scale, cY * scale);
		return mapping.exists(colorInt) ? mapping[colorInt] : EMPTY;
	}
}