package entities;

import helpers.CardinalMaker;
import states.PlayState;
import echo.Body;
import echo.data.Data.CollisionData;
import flixel.util.FlxColor;
import collision.ColorCollideSprite;

using echo.FlxEcho;

@:access(echo.FlxEcho)
class Transition extends ColorCollideSprite {
	var data:Entity_Door;
	var body:Body;

	public function new(data:Entity_Door) {
		super(data.pixelX, data.pixelY, Color.fromStr(data.f_Color.getName()));
		this.data = data;
		makeGraphic(16, 48, FlxColor.WHITE);

		body = this.add_body({
			x: data.pixelX,
			y: data.pixelY - 24,
			// mass: STATIC,
			kinematic: true,
			rotation: angle,
			shape: {
				type: RECT,
				width: data.width,
				height: data.height,
				solid: false,
			}
		});

		body.update_body_object();
	} 

	override function handleEnter(other:Body, colData:Array<CollisionData>) {
		super.handleEnter(other, colData);

		if (other.object is Player) {
			var player:Player = cast other.object;
			if (!player.inControl) {
				return;
			}
			FlxEcho.updates = false;
			FlxEcho.instance.active = false;
			player.transitionWalk(CardinalMaker.fromString(data.f_access_dir.getName()).opposite(), () -> {
				PlayState.ME.loadLevel(data.f_Entity_ref.levelIid, data.f_Entity_ref.entityIid);
			});
		}
	}
}