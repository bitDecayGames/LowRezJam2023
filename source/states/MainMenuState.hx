package states;

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

class MainMenuState extends FlxState {
	override public function create():Void {
		super.create();

		FmodManager.PlaySong(FmodSongs.LetsGo);
		bgColor = FlxColor.TRANSPARENT;
		FlxG.camera.pixelPerfectRender = true;

		var bg = new FlxSprite(AssetPaths.title_bg__png);
		bg.screenCenter();
		add(bg);

		var title = new FlxSprite(AssetPaths.title__png);
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
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.keys.pressed.D && FlxG.keys.justPressed.M) {
			// Keys D.M. for Disable Metrics
			Bitlytics.Instance().EndSession(false);
			FmodManager.PlaySoundOneShot(FmodSFX.MenuSelect);
			trace("---------- Bitlytics Stopped ----------");
		}

		if (SimpleController.just_pressed(START)) {
			clickPlay();
		}
	}

	function clickPlay():Void {
		FmodManager.StopSong();
		var swirlOut = new SwirlTransition(TransitionDirection.OUT, () -> {
			// make sure our music is stopped;
			FmodManager.StopSongImmediately();
			FlxG.switchState(new PlayState());
		}, FlxColor.GRAY, 0.75);
		openSubState(swirlOut);
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
