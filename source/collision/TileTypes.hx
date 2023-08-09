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
		var objs = buildForLayer(level.raw.l_Terrain_coarse, level.raw);
		return objs.concat(buildForLayer(level.raw.l_Terrain_fine, level.raw));
	}

	// This is taken from the ldtk codebase so that we can augment it to add color and attach echo bodies
	@:access(ldtk.Layer_Tiles)
	@:access(echo.FlxEcho)
	static function buildForLayer(layer:Layer_Tiles, raw:LDTKProject_Level):Array<FlxObject> {
		// a way to know which tiles we've processed already when combining hitboxes
		var handled = new Map<Int, Bool>();
		var colorLayer:Layer_TerrainColor = raw.l_TerrainColor;
		var tiles:Array<FlxObject> = [];
		for( cy in 0...layer.cHei ) {
			for( cx in 0...layer.cWid ) {
				if (handled.exists(getCoordId(cx, cy, layer.cWid))) {
					continue;
				}

				if( layer.hasAnyTileAt(cx,cy) ) {
					for( tile in layer.getTileStackAt(cx,cy) ) {
						if (tile.tileId == 0) {
							continue;
						}

						var color = TileTypes.getColorFromTile(cx, cy, layer.gridSize, colorLayer);

						var rectWidthC = 1;
						// scan right to see how large our body can be
						for (nextX in cx+1...layer.cWid) {
							if (!handled.exists(getCoordId(nextX, cy, layer.cWid)) && hasMatch(layer, nextX, cy, color, colorLayer)) {
								rectWidthC++; 
							} else {
								break;
							}
						}

						var rectHeightC = 1;
						// scan down to see how large our body can be
						for (nextY in cy+1...layer.cHei) {
							var rowMatch = true;
							for (nextX in 0...rectWidthC) {
								if (!handled.exists(getCoordId(cx+nextX, nextY, layer.cWid)) && !hasMatch(layer, cx+nextX, nextY, color, colorLayer)) {
									rowMatch = false; 
									break;
								}
							}
							if (rowMatch) {
								rectHeightC++;
							} else {
								break;
							}
						}

						var xPix = cx*layer.gridSize + layer.pxTotalOffsetX;
						var yPix = cy*layer.gridSize + layer.pxTotalOffsetY;
						var b = new Body({
							x: xPix,
							y: yPix,
							mass: STATIC,
							shape: {
								type: RECT,
								width: layer.gridSize * rectWidthC,
								height: layer.gridSize * rectHeightC,
								offset_x: (layer.gridSize * rectWidthC) * 0.5,
								offset_y: (layer.gridSize * rectHeightC) * 0.5
							}
						});

						// mark all the tiles we handled here in the grid
						var firstTile = true;
						for (w in 0...rectWidthC) {
							for (h in 0...rectHeightC) {
								handled.set(getCoordId(cx + w, cy + h, layer.cWid), true);

								// and build our sprites so we get nice rendering
								var sprCx = cx + w;
								var sprCy = cy + h;
								var xSpr = sprCx*layer.gridSize + layer.pxTotalOffsetX;
								var ySpr = sprCy*layer.gridSize + layer.pxTotalOffsetY;
						
								var s:FlxSprite;
								if (color != EMPTY) {
									s = new ColorCollideSprite(xSpr, ySpr, color);
								} else {
									s = new FlxSprite(xSpr, ySpr);
								}

								var sprTileId = layer.getTileStackAt(sprCx, sprCy)[0].tileId;
		
								s.flipX = tile.flipBits & 1 != 0;
								s.flipY = tile.flipBits & 2 != 0;
								s.frame = layer.untypedTileset.getFrame(sprTileId).copyTo();
								s.width = layer.gridSize;
								s.height = layer.gridSize;

								if (firstTile) {
									// we only have one body, so we'll attach it to the first tile (top-left) of the physics body
									firstTile = false;
									s.set_body(b);
									b.update_body_object();
								}
								tiles.push(s);
							}
						}
					}
				}
			}
		}
		
		return tiles;
	}

	static function hasMatch(layer:Layer_Tiles, cx:Int, cy:Int, color:Color, colorLayer:Layer_TerrainColor):Bool {
		if(!layer.hasAnyTileAt(cx,cy) ) {
			return false;
		} else {
			for( tile in layer.getTileStackAt(cx,cy) ) {
				if (tile.tileId == 0) {
					continue;
				}

				var foundColor = TileTypes.getColorFromTile(cx, cy, layer.gridSize, colorLayer);
				return foundColor == color;
			}
		}
		
		return false;
	}

	static function getCoordId(cx,cy, gridWidthInCells) {
		return cx+cy*gridWidthInCells;
	}

	public static function getColorFromTile(cX:Int, cY:Int, gridSize:Int, colors:Layer_TerrainColor):Color {
		var scale:Int = Std.int(gridSize / colors.gridSize);
		var colorInt = colors.getInt(cX * scale, cY * scale);
		return mapping.exists(colorInt) ? mapping[colorInt] : EMPTY;
	}
}