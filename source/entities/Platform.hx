package entities;

import collision.ColorCollideSprite;
import collision.Constants;
import flixel.util.FlxColor;
import flixel.FlxSprite;

using echo.FlxEcho;

class Platform extends ColorCollideSprite {
	public function new(X:Float, Y:Float) {
		super(X, Y, EMPTY);

		makeGraphic(32, 32, FlxColor.GRAY, true);

		this.add_body({
			x: X,
			y: Y,
			kinematic: true,
			shape: {
				type: RECT,
				width: Constants.BLOCK_SIZE, // we should be able to pull this from the aseprite file, maybe?
				height: Constants.BLOCK_SIZE,
			}
		});
	}
}