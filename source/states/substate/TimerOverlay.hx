package states.substate;

import flixel.FlxSubState;
import flixel.util.FlxColor;
import helpers.Storage;
import openfl.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import ui.font.BitmapText;
import flixel.math.FlxRect;
import input.SimpleController;
import flixel.FlxSprite;

class TimerOverlay extends FlxSubState {
	public static var ME:TimerOverlay;

	public static var mapTimer:Float = 0.0;
	var timerTxt = new BitmapText();

	public function new() {
		super();
		ME = this;
	}

	override function create() {
		super.create();
		buildOverlay();
	}

	function buildOverlay() {
		timerTxt.screenCenter(X);
		timerTxt.y = 5;
		timerTxt.text = "00:00";
		timerTxt.scrollFactor.set();
		add(timerTxt);

		add(timerTxt);
	}

	override public function update(delta:Float) {
		super.update(delta);
	}
}