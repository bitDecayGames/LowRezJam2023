package collision;

import echo.Body;
import echo.data.Data.CollisionData;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class ColorCollideSprite extends FlxSprite {
	public var interactColor:Color;

	public function new(X:Float, Y:Float, initialColor:Color) {
		super(X, Y);
		interactColor = initialColor;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		color = cast interactColor;
	}

	public function addColor(i:Color) {
		interactColor = interactColor.add(i);

	}

	public function removeColor(i:Color) {
		interactColor = interactColor.sub(i);
	}

	public function handleEnter(other:Body, data:Array<CollisionData>) {

	}

	public function handleExit(other:Body) {
		
	}
}