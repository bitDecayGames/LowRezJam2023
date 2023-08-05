package entities;

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
				height: data.height,
				solid: false,
			}
		});
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		// TODO: Cutscene

		if (other.object is Player) {
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