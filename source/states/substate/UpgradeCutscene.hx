package states.substate;

import flixel.math.FlxPoint;
import flixel.FlxSprite;
import collision.Color;
import entities.DummyPlayer;
import flixel.util.FlxColor;
import flixel.FlxG;
import entities.UnlockParticle;
import flixel.FlxSubState;

using bitdecay.flixel.extensions.FlxObjectExt;

class UpgradeCutscene extends FlxSubState {
	var finishCb:Void->Void = null;

	var upgradeColor:Color;

	var screenPoint:FlxPoint;
	var offset = FlxPoint.get(2, -2);

	var power:FlxSprite;
	var player:FlxSprite;

	var flipped = false;

	public function new(flip:Bool, playerPoint:FlxPoint, upgradeColor:Color, ?cb:Void->Void) {
		super();
		flipped = flip;
		screenPoint = offset.copyTo().addPoint(playerPoint);
		this.upgradeColor = upgradeColor;
		finishCb = cb;

		camera = PlayState.ME.objectCam;
	}

	override function create() {
		super.create();

		PlayState.ME.objectCam.fade(FlxColor.BLACK, .3, true);

		var bg = new FlxSprite();
		bg.makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width + 32, FlxG.height + 32);
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		player = new DummyPlayer(0,0);
		player.scrollFactor.set();
		player.setPositionMidpoint(screenPoint.x, screenPoint.y);
		player.flipX = flipped;
		add(player);

		power = new UnlockParticle(0,0, done, () -> {
			PlayState.ME.objectCam.flash(cast upgradeColor, 0.1);
			PlayState.ME.objectCam.shake(0.01, 0.4);
			player.color = cast upgradeColor;
		});
		power.flipX = flipped;
		power.color = cast upgradeColor;
		power.scrollFactor.set();
		power.setPositionMidpoint(screenPoint.x, screenPoint.y);

		add(power);
	}

	function done() {
		PlayState.ME.objectCam.fade(FlxColor.BLACK, 0.5, () -> {
			power.kill();
			player.kill();
			bgColor = FlxColor.TRANSPARENT;
			if (finishCb != null) {
				finishCb();
			}
		});
	}
}