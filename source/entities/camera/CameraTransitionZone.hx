package entities.camera;

import states.PlayState;
import bitdecay.flixel.spacial.Cardinal;
import collision.ColorCollideSprite;
import echo.Body;
import flixel.math.FlxRect;
import flixel.FlxObject;

using echo.FlxEcho;

class CameraTransitionZone extends ColorCollideSprite {
	var area:FlxRect;
	var camGuides = new Map<Cardinal, FlxRect>();

	public function new(area:FlxRect) {
		this.area = area;
		super(area.x, area.y, EMPTY);
		visible = false;
		interactsWithOthers = false;
	}

	override function makeBody():Body {
		return this.add_body({
			x: area.x + area.width / 2,
			y: area.y + area.height / 2,
			kinematic: true,
			shape: {
				type:RECT,
				solid: false,
				width: area.width,
				height: area.height,
			}
		});
	}

	public function addGuideTrigger(dir:Cardinal, guideZone:FlxRect) {
		camGuides.set(dir, guideZone);
	}

	override function handleExit(other:Body) {
		super.handleExit(other);

		if (other.object is Player) {
			var player:Player = cast other.object;
			for (dir => camZone in camGuides) {
				switch(dir) {
					case N:
						if (player.body.y < area.top) {
							PlayState.ME.setCameraBounds(camZone);
						}
					case S:
						if (player.body.y > area.bottom) {
							PlayState.ME.setCameraBounds(camZone);
						}
					case E:
						if (player.body.x > area.right) {
							PlayState.ME.setCameraBounds(camZone);
						}
					case W:
						if (player.body.x < area.left) {
							PlayState.ME.setCameraBounds(camZone);
						}
					default:
						QuickLog.error('camera transition area has unsuppored cardinal direction ${dir}');
				}
			}
		}
	}
}