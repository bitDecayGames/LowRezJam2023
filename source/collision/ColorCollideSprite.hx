package collision;

import states.PlayState;
import bitdecay.flixel.debug.DebugDraw;
import flixel.FlxG;
import entities.Player;
import flixel.tweens.FlxTween;
import echo.Body;
import echo.data.Data.CollisionData;
import flixel.util.FlxColor;
import flixel.FlxSprite;


class ColorCollideSprite extends FlxSprite {
	var lastColor:Int;
	public var interactColor:Color;
	var colorTime = 0.0;
	var transitionLength = 0.15;

	public function new(X:Float, Y:Float, initialColor:Color) {
		super(X, Y);
		lastColor = initialColor;
		interactColor = initialColor;
		if (initialColor != Color.EMPTY) {
			// color = cast initialColor;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		colorTime = Math.min(transitionLength, colorTime + elapsed);
		
		if (lastColor == interactColor) {
			// color = interactColor.toFlxColor();
		} else {
			var val = FlxColor.interpolate(cast lastColor, cast interactColor, colorTime / transitionLength);
			// if (this is Player) {
			// 	var lastCast:FlxColor = cast lastColor;
			// 	var curCast:FlxColor = cast interactColor;
			// 	FlxG.watch.addQuick("colorTime: ", colorTime);
			// 	FlxG.watch.addQuick("lastCast: ", lastCast);
			// 	FlxG.watch.addQuick("curCast: ", curCast);
	
			// 	DebugDraw.ME.drawWorldCircle(PlayState.ME.dbgCam, x -10, y - 10, 3, null, val);
			// }
			color = val;
		}
	}

	public function addColor(i:Color) {
		var tmp = interactColor;
		interactColor = interactColor.add(i);
		if (tmp != interactColor) {
			lastColor = tmp;
			colorTime = 0.0;
		}
	}

	public function removeColor(i:Color) {
		var tmp = interactColor;
		interactColor = interactColor.sub(i);
		if (tmp != interactColor) {
			lastColor = tmp;
			colorTime = 0.0;
		}
	}

	public function handleEnter(other:Body, data:Array<CollisionData>) {

	}

	public function handleStay(other:Body, data:Array<CollisionData>) {

	}

	public function handleExit(other:Body) {
		
	}
}