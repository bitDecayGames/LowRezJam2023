package states;

import flixel.addons.ui.FlxUIState;
import input.SimpleController;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.FlxState;
import bitdecay.flixel.transitions.TransitionDirection;
import bitdecay.flixel.transitions.SwirlTransition;
import states.AchievementsState;
import com.bitdecay.analytics.Bitlytics;
import flixel.FlxG;
import flixel.addons.ui.FlxUITypedButton;
import flixel.util.FlxColor;
import haxefmod.flixel.FmodFlxUtilities;

using states.FlxStateExt;

class MainMenuState extends FlxUIState {
	var started = false;

	var title:FlxSprite = null;
	var pressStart:FlxSprite = null;

	override public function create():Void {
		super.create();

		bgColor = FlxColor.TRANSPARENT;
		FlxG.camera.pixelPerfectRender = true;

		var bg = new FlxSprite(AssetPaths.title_bg__png);
		bg.screenCenter();
		add(bg);

		title = new FlxSprite(AssetPaths.title__png);
		add(title);

		title.y = 6;
		FlxTween.tween(title, {y: title.y + 10}, {
			ease: FlxEase.sineInOut,
			type: FlxTweenType.PINGPONG,
		});
		title.angle = -5;
		FlxTween.tween(title, {angle: title.angle + 10}, 1.2, {
			ease: FlxEase.sineInOut,
			type: FlxTweenType.PINGPONG,
		});

		pressStart = new FlxSprite(AssetPaths.pressEnter__png);
		pressStart.setPosition(FlxG.width - pressStart.width - 10, 164);
		add(pressStart);

		FlxTween.tween(pressStart, {"scale.x": 1.2, "scale.y": 1.2, y: pressStart.y - 8}, 0.7, {
			ease: FlxEase.sineInOut,
			type: FlxTweenType.PINGPONG,
		});
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.keys.pressed.D && FlxG.keys.justPressed.M) {
			// Keys D.M. for Disable Metrics
			Bitlytics.Instance().EndSession(false);
			FmodManager.PlaySoundOneShot(FmodSFX.PlayerDieBurst2);
			trace("---------- Bitlytics Stopped ----------");
		}

		if (!started && SimpleController.just_pressed(START)) {
			started = true;
			FmodManager.PlaySoundOneShot(FmodSFX.PlayerDieBurst2);

			FlxTween.tween(title, {alpha: 0}, 0.75);
			FlxTween.tween(pressStart, {alpha: 0}, 0.75);

			clickPlay();
		}
	}

	function clickPlay():Void {
		FmodFlxUtilities.TransitionToStateAndStopMusic(new PlayState());
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
