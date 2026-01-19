package states;

import progress.Collected;
import io.newgrounds.NG;
import config.Newgrounds;
import com.bitdecay.analytics.Bitlytics;
import openfl.events.MouseEvent;
#if js
import js.Browser;
import js.html.OrientationLockType;
import js.html.audio.AudioContextState;
import openfl.events.TouchEvent;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;


class ClickToFocusState extends FlxState {
var clickHere:FlxSprite = null;

	var pauseTime:Float = 0.0;


	override function create() {
		super.create();

		clickHere = new FlxSprite(AssetPaths.clickHere__png);
		// clickHere = new FlxSprite();
		clickHere.setPosition(FlxG.width - clickHere.width - 10, 164);
		clickHere.screenCenter();
		clickHere.scale.set(2, 2);

		add(clickHere);

		clickHere.y - 5;
		FlxTween.tween(clickHere, {y: clickHere.y + 10}, {
			ease: FlxEase.sineInOut,
			type: FlxTweenType.PINGPONG,
		});
		clickHere.angle = -5;
		FlxTween.tween(clickHere, {angle: clickHere.angle + 10}, 1.2, {
			ease: FlxEase.sineInOut,
			type: FlxTweenType.PINGPONG,
		});
	}

	override function destroy() {
		super.destroy();
	}

	var justOnce = true;
	var fmodLoaded = false;
	var checkFmod = false;
	var checkNGLoggedIn = false;

	var state = "wait_for_input";

	override function update(elapsed:Float) {
		if (pauseTime > 0) {
			pauseTime -= elapsed;
			return;
		}

		super.update(elapsed);

		switch state {
			case "wait_for_input":
				var go = FlxG.mouse.justPressed;
				if (FlxG.onMobile) {
					go = go || FlxG.touches.getFirst() != null;
				}
				if (go) {
					state = "init_fmod";
				}
			case "init_fmod":
				#if html5
				// On web, we may have to resume audio in response to user input
				lime.media.AudioManager.context.web.resume();

				state = "wait_for_web_state";

				var checks = 0;
				var checkLimit = 30;
				new FlxTimer().start(0.1, (t) -> {
					checks++;
					if (checks % 10 == 0) {
						FlxG.log.notice('checking for audio resume ($checks)');
					}

					// TODO: ios _may_ have the context.web.state might be undefined
					if (checks > checkLimit || lime.media.AudioManager.context.web.state == AudioContextState.RUNNING) {
						#if debug
						trace('audio context is now running! took ${checks} checks');
						#end

						#if debug
						if (checks > checkLimit) {
							trace("I'm giving up on waiting for resume...");
						}
						#end

						FmodManager.ResumeAudio();
						state = "check_ng_login";
						t.cancel();
					} else {
						#if debug
						trace(checks);
						#end
						lime.media.AudioManager.context.web.resume();
					}
				}, 0);
				#else
				// Whereas on other targets, audio is just fine
				state = "wait_for_fmod";
				#end
			case "wait_for_web_state":

			case "wait_for_fmod":
				if (!fmodLoaded && FmodManager.IsInitialized()) {
					// TODO: ios doesn't seem to finish init'ing fmod :'(
					state = "check_ng_login";
				}
			case "check_ng_login":
				if (NG.core != null && !NG.core.loggedIn && !NG.core.attemptingLogin) {
					Newgrounds.requestLogin(
						() -> {
							state = "go_to_splash";
						},
						() -> {
							state = "go_to_splash";
						}
					);
				}
				state = "wait_for_ng_or_skip";
			case "wait_for_ng_or_skip":
				var go = FlxG.mouse.justPressed;
				if (FlxG.onMobile) {
					go = go || FlxG.touches.getFirst() != null;
				}
				go = go || NG.core.loggedIn;
				if (go) {
					state = "go_to_splash";
				}
			case "go_to_splash":
				if (Collected.getCheckpointLevel() != null) {
					FlxG.switchState(new MainMenuState());
				} else {
					FlxG.switchState(new SplashScreenState());
				}
		}
	}
}