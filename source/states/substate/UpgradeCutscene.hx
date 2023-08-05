package states.substate;

import flixel.FlxSprite;
import collision.Color;
import entities.DummyPlayer;
import flixel.util.FlxColor;
import flixel.FlxG;
import entities.UnlockParticle;
import flixel.FlxSubState;

class UpgradeCutscene extends FlxSubState {
	var finishCb:Void->Void = null;

	var upgradeColor:Color;

	var power:FlxSprite;
	var player:FlxSprite;

	public function new(upgradeColor:Color, ?cb:Void->Void) {
		super(FlxColor.BLACK);
		this.upgradeColor = upgradeColor;
		finishCb = cb;
	}

	override function create() {
		super.create();

		FlxG.camera.fade(FlxColor.BLACK, .2, true);

		player = new DummyPlayer(0,0);
		player.scrollFactor.set();
		player.screenCenter();
		add(player);

		power = new UnlockParticle(0,0, done, () -> {
			FlxG.camera.flash(cast upgradeColor, 0.1);
			FlxG.camera.shake(0.005, 0.4);
			player.color = cast upgradeColor;
		});

		power.color = cast upgradeColor;
		power.scrollFactor.set();
		power.screenCenter();
		add(power);
	}

	function done() {
		FlxG.camera.fade(FlxColor.BLACK, 0.5, () -> {
			power.kill();
			player.kill();
			bgColor = FlxColor.TRANSPARENT;
			FlxG.camera.fade(FlxColor.BLACK, 0.1, true, () -> {
				close();
				if (finishCb != null) {
					finishCb();
				}
			});
		});
	}
}