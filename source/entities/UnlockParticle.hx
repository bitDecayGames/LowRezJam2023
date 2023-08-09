package entities;

import flixel.FlxG;
import loaders.Aseprite;
import loaders.AsepriteMacros;
import flixel.FlxSprite;

using bitdecay.flixel.extensions.FlxObjectExt;

class UnlockParticle extends FlxSprite {
	private static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/powerUp.json");
	public static var eventData = AsepriteMacros.frameUserData("assets/aseprite/characters/powerUp.json", "main");


	var cb:Void->Void;

	public function new(centerX:Float, centerY:Float, finishCB:Void->Void, tintCB:Void->Void) {
		super(centerX, centerY);
		this.cb = finishCB;

		Aseprite.loadAllAnimations(this, AssetPaths.powerUp__json);
		animation.play(anims.power);
		FmodManager.PlaySoundOneShot(FmodSFX.ColorStart);
		animation.finishCallback = finished;

		animation.callback = (anim, frame, index) -> {
			if (eventData.exists(index)) {
				if (StringTools.contains(eventData.get(index), "start_tint")) {
					tintCB();
				}
				
				if (StringTools.contains(eventData.get(index), "flash")) {
					FmodManager.PlaySoundOneShot(FmodSFX.ColorFlash2);
					FmodManager.PlaySoundOneShot(FmodSFX.ColorCharge2);
				}

				
				if (StringTools.contains(eventData.get(index), "charge_end")) {
					// upgrade hits player
				}
				
				if (StringTools.contains(eventData.get(index), "shoot")) {
					FmodManager.PlaySoundOneShot(FmodSFX.ColorShoot);
				}
			}
		};

		this.setPositionMidpoint(centerX, centerY);
	}

	function finished(name:String) {
		if (cb != null) {
			cb();
		}
		// kill();
	}
}