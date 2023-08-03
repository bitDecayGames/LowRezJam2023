package;

import shaders.ShaderUpdater;
import shaders.PixelateShader;
import flixel.FlxCamera;
import openfl.display.Sprite;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;

import flixel.system.FlxAssets.FlxShader;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.util.FlxColor;

import bitdecay.flixel.debug.DebugDraw;

import achievements.Achievements;
import audio.FmodPlugin;
import config.Configure;
import debug.DebugLayers;
import helpers.Storage;
import misc.FlxTextFactory;
import misc.Macros;
import states.SplashScreenState;
import states.MainMenuState;

#if FLX_DEBUG
import flixel.system.debug.log.LogStyle;
#end

#if play
import states.PlayState;
#end
#if credits
import states.CreditsState;
#end

class Main extends Sprite {
	public function new() {
		super();
		Configure.initAnalytics(false);

		Storage.load();
		Achievements.initAchievements();

		var startingState:Class<FlxState> = SplashScreenState;
		#if play
		startingState = PlayState;
		#elseif credits
		startingState = CreditsState;
		#else
		if (Macros.isDefined("SKIP_SPLASH")) {
			startingState = MainMenuState;
		}
		#end
		var game = new FlxGame(256, 256, startingState, 60, 60, true, false);
		addChild(game);
		
		// FlxG.camera.scroll.set(3 * FlxG.camera.width, 3 * FlxG.camera.height);

		// force chunky pixel appearance
		var shaderUpdater = new ShaderUpdater();
		FlxG.plugins.add(shaderUpdater);
		var setCameraShader = () -> {
			var pixelShader = new PixelateShader();
			FlxG.camera.setFilters( [new ShaderFilter(pixelShader)] ); 
			shaderUpdater.setShader(pixelShader);
		};

		// call it once on startup
		setCameraShader();
		// then every time we switch states
		FlxG.signals.preStateSwitch.add(setCameraShader);
		
		// FlxG.game.stage.quality = StageQuality.LOW;

		FlxG.fixedTimestep = false;

		// Disable flixel volume controls as we don't use them because of FMOD
		FlxG.sound.muteKeys = null;
		FlxG.sound.volumeUpKeys = null;
		FlxG.sound.volumeDownKeys = null;

		// Don't use the flixel cursor
		FlxG.mouse.useSystemCursor = true;

		#if debug
		FlxG.autoPause = false;
		#end

		// Set up basic transitions. To override these see `transOut` and `transIn` on any FlxTransitionable states
		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.35);
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.35);

		// Set any default font you want to be the default
		// FlxTextFactory.defaultFont = AssetPaths.Brain_Slab_8__ttf;
		FlxTextFactory.defaultSize = 24;

		FlxG.plugins.add(new FmodPlugin());

		DebugDraw.init(Type.allEnums(DebugLayers));

		configureLogging();
	}

	private function configureLogging() {
		#if FLX_DEBUG
		LogStyle.WARNING.openConsole = true;
		LogStyle.WARNING.callbackFunction = () -> {
			// Make sure we open the logger if a log triggered
			FlxG.game.debugger.log.visible = true;
		};

		LogStyle.ERROR.openConsole = true;
		LogStyle.ERROR.callbackFunction = () -> {
			// Make sure we open the logger if a log triggered
			FlxG.vcr.pause();
			FlxG.game.debugger.log.visible = true;
		};
		#end
	}
}
