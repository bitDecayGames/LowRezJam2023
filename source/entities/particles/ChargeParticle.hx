package entities.particles;

import loaders.AsepriteMacros;
import loaders.Aseprite;
import flixel.FlxSprite;
import collision.Color;

class ChargeParticle extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/charge.json");

	public function new(X:Float, Y:Float, c:Color) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.charge__json);
		animation.add("all", [for (i in 0...animation.numFrames) i], 30);
		animation.play('all', true, false, -1);
		scale.set(0.75, 0.75);
		alpha = 0.5;

		for (f in animation.getByName('all').frames) {
			// Thanks aseprite, but we want to manage these manually
			frames.frames[f].duration = 0;
		}
		color = cast c;
	}
}