package entities;

import states.substate.UpgradeCutscene;
import flixel.util.FlxColor;
import flixel.FlxG;
import states.PlayState;
import progress.Collected;
import collision.Color;
import echo.data.Data.CollisionData;
import collision.ColorCollideSprite;
import echo.Body;
import loaders.Aseprite;
import loaders.AsepriteMacros;

using echo.FlxEcho;

class ColorUpgrade extends ColorCollideSprite {
	private static var anims = AsepriteMacros.tagNames("assets/aseprite/pixel.json");

	public var body:Body;
	var colorToUnlock:Color;

	public function new(data:Entity_Color_upgrade) {
		super(data.pixelX, data.pixelY - data.height/2, EMPTY);

		colorToUnlock = Color.fromEnum(data.f_Color);

		Aseprite.loadAllAnimations(this, AssetPaths.pixel__json);
		animation.play(anims.float);

		body = this.add_body({
			x: data.pixelX,
			y: data.pixelY - data.height/2,
			kinematic: true,
			rotation: angle,
			shape: {
				type: RECT,
				width: 10,
				height: 5,
				offset_y: data.height / 2 - 5/2,
				solid: false,
			}
		});
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		FlxEcho.updates = false;
		FlxEcho.instance.active = false;

		FlxG.camera.fade(FlxColor.BLACK, 0.2, () -> {
			FlxG.state.openSubState(new UpgradeCutscene(colorToUnlock, () -> {
				FlxEcho.updates = true;
				FlxEcho.instance.active = true;
			}));
		});

		if (other.object is Player) {
			var player:Player = cast other.object;
			player.forceStand();
			switch(colorToUnlock) {
				case RED:
					Collected.unlockRed();
				case YELLOW:
					Collected.unlockYellow();
				case BLUE:
					Collected.unlockBlue();
				default:
					QuickLog.error('pixel upgrade trying to unlock ${colorToUnlock.name()}');
			}
		}

		kill();
		body.active = false;
	}
}