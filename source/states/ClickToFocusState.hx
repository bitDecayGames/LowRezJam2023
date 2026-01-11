package states;

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

	override function update(elapsed:Float) {
		if (pauseTime > 0) {
			pauseTime -= elapsed;
			return;
		}

		super.update(elapsed);

		var go = FlxG.mouse.justPressed;

		if (FlxG.onMobile) {
			go = go || FlxG.touches.getFirst() != null;
		}

		if (justOnce && go) {
			justOnce = false;

			#if html5
			// On web, we may have to resume audio in response to user input
			lime.media.AudioManager.context.web.resume();

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
					checkFmod = true;
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
			checkFmod = true;
			#end
		}

		// This is intentionally setup so that we don't call FmodManager until after the booleans are correct (short circuiting)
		// because calling `IsInitialized()` will cause it to initialize on HTML5 builds
		if (checkFmod && !fmodLoaded && FmodManager.IsInitialized()) {
			// TODO: ios doesn't seem to finish init'ing fmod :'(

			fmodLoaded = true;
			FlxG.switchState(new SplashScreenState());
		}
	}
}