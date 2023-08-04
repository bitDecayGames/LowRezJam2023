package states;

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

	public var player:Player;
	public var dbgCam:FlxCamera;
	
	public var pendingObjects = new Array<FlxObject>();
	public var pendingLasers = new Array<FlxObject>();

	public var playerGroup = new FlxGroup();
	public var objects = new FlxGroup();
	public var lasers = new FlxGroup();

	public function new() {
		super();
		ME = this;
	}

	override public function create() {
		super.create();
		Lifecycle.startup.dispatch();

		FlxEcho.init({width: FlxG.width, height: FlxG.height, gravity_y: 24 * Constants.BLOCK_SIZE});

		#if debug
		FlxEcho.draw_debug = true;
		#end

		FlxG.camera.bgColor = FlxColor.GRAY.getDarkened(0.8);

		dbgCam = new FlxCamera();
		dbgCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(dbgCam, false);

		add(objects);
		add(playerGroup);
		add(lasers);

		var level = new levels.ldtk.Level("Level_0");

		camera.setScrollBoundsRect(0, 0, level.bounds.width, level.bounds.height);
		dbgCam.setScrollBoundsRect(0, 0, level.bounds.width, level.bounds.height);
		FlxEcho.instance.world.set(0, 0, level.bounds.width, level.bounds.height);

		var levelBodies = TileMap.generate_grid(level.rawTerrainInts,
			Constants.BLOCK_SIZE,
			Constants.BLOCK_SIZE,
			level.rawTerrainTilesWide,
			level.rawTerrainTilesTall);
		
		var tmpAABB = AABB.get();
		for (body in levelBodies) {
			body.shape.bounds(tmpAABB);
			var gridCell = FlxPoint.get(tmpAABB.min_x / level.rawTerrainLayer.gridSize, tmpAABB.min_y / level.rawTerrainLayer.gridSize);
			if (!level.rawTerrainLayer.hasAnyTileAt(Std.int(gridCell.x), Std.int(gridCell.y))){
				trace('whut');
			}
			var tStack = level.rawTerrainLayer.getTileStackAt(Std.int(gridCell.x), Std.int(gridCell.y));
			var tileID = tStack[0].tileId;
			var fillerBodySprite = new ColorCollideSprite(body.x, body.y, collision.TileTypes.mapping[tileID]);
			fillerBodySprite.makeGraphic(Std.int(tmpAABB.width), Std.int(tmpAABB.height));
			fillerBodySprite.set_body(body);
			fillerBodySprite.add_to_group(objects);
			fillerBodySprite.visible = false;
		}

		add(level.terrainGfx);

		for (o in level.objects) {
			o.add_to_group(objects);
		}

		player = level.player;
		player.add_to_group(playerGroup);

		camera.follow(player, FlxCameraFollowStyle.PLATFORMER, .5);
		dbgCam.follow(player, FlxCameraFollowStyle.PLATFORMER, .5);

		for (emitter in level.emitters) {
			add(emitter);
		}

		FlxEcho.listen(playerGroup, lasers, {
			condition: Collide.colorsInteract,
			enter: (a, b, o) -> {
				if (Std.isOfType(a.object, ColorCollideSprite)) {
					cast(a.object, ColorCollideSprite).handleEnter(b, o);
				}
				if (Std.isOfType(b.object, ColorCollideSprite)) {
					cast(b.object, ColorCollideSprite).handleEnter(a, o);
				}
			},
		});

		FlxEcho.listen(player, objects, {
			condition: Collide.colorsInteract,
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

		// QuickLog.error('Example error');
	}

	public function addLaser(laser:LaserBeam) {
		laser.add_to_group(lasers);
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
