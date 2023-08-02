package states;

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

class PlayState extends FlxTransitionableState {
	var player:FlxSprite;
	var dbgCam:FlxCamera;

	override public function create() {
		super.create();
		Lifecycle.startup.dispatch();

		FlxG.camera.bgColor = FlxColor.GRAY.getDarkened(0.5);
		// FlxG.camera.scale

		FlxG.camera.pixelPerfectRender = true;

		// var defaultCam = FlxG.camera;
		// FlxG.cameras.reset(defaultCam);
		dbgCam = new FlxCamera();
		dbgCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(dbgCam, false);

		// player = new Player();
		// add(player);

		// var item = new Item();
		// item.y = 50;
		// add(item);

		// add(Achievements.ACHIEVEMENT_NAME_HERE.toToast(true, true));

		player = new Player();
		player.screenCenter();
		add(player);

		QuickLog.error('Example error');
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var cam = FlxG.camera;
		DebugDraw.ME.drawCameraRect(dbgCam, cam.getCenterPoint().x - 5, cam.getCenterPoint().y - 5, 10, 10, DebugLayers.RAYCAST, FlxColor.RED);
		DebugDraw.ME.drawCameraRect(dbgCam, 0, 0, 3, 3);
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
