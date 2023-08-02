package collision;

import echo.Body;
import echo.data.Data.CollisionData;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class ColorCollideSprite extends FlxSprite {
	public function new(X:Float, Y:Float, initialColor:FlxColor) {
		super(X, Y);
		color = initialColor;
	}

	public function handleEnter(other:Body, data:Array<CollisionData>) {

	}

	public function handleExit(other:Body) {
		
	}
}