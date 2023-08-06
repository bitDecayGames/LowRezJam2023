package entities;

import helpers.CardinalMaker;
import states.PlayState;
import echo.Body;
import echo.data.Data.CollisionData;
import flixel.util.FlxColor;
import collision.ColorCollideSprite;
import loaders.Aseprite;
import loaders.AsepriteMacros;

using echo.FlxEcho;

@:access(echo.FlxEcho)
class Transition extends ColorCollideSprite {
	private static var anims = AsepriteMacros.tagNames("assets/aseprite/door.json");

	public var doorID:String;

	var transitionCb:Void->Void = null;

	var data:Entity_Door;
	var body:Body;

	public function new(data:Entity_Door) {
		super(data.pixelX, data.pixelY, Color.fromStr(data.f_Color.getName()));
		this.data = data;
		doorID = data.iid;
		
		Aseprite.loadAllAnimations(this, AssetPaths.door__json);

		animation.callback = (name, frameNumber, frameIndex) -> {
			if (name == anims.activate || name == anims.deactivate) {
				FmodManager.PlaySoundOneShot(FmodSFX.DoorTick);
			}
		}

		animation.finishCallback = animFinished;
		animation.play(anims.closed);

		body = this.add_body({
			x: data.pixelX,
			y: data.pixelY - data.height/2,
			kinematic: true,
			rotation: angle,
			shape: {
				type: RECT,
				width: data.width,
				height: data.height,
				// solid: false,
			}
		});

		body.update_body_object();
	}

	public function open(?cb:Void->Void) {
		animation.play(anims.activate);
		transitionCb = cb;
	}

	public function close(?cb:Void->Void) {
		animation.play(anims.deactivate);
		transitionCb = cb;
	}

	override function handleEnter(other:Body, colData:Array<CollisionData>) {
		super.handleEnter(other, colData);
	}

	override function handleStay(other:Body, colData:Array<CollisionData>) {
		super.handleStay(other, colData);

		if (other.object is Player) {
			var player:Player = cast other.object;
			if (!player.inControl) {
				return;
			}

			if (!player.grounded) {
				return;
			}

			FlxEcho.updates = false;
			FlxEcho.instance.active = false;

			animation.play(anims.activate);

			player.forceStand();

			transitionCb = () -> {
				player.transitionWalk(CardinalMaker.fromString(data.f_access_dir.getName()).opposite(), () -> {
					PlayState.ME.loadLevel(data.f_Entity_ref.levelIid, data.f_Entity_ref.entityIid);
				});
			}
		}
	}

	function animFinished(name:String) {
		if (name == anims.activate) {
			if (transitionCb != null) {
				transitionCb();
				transitionCb = null;
			}
		}
	}
}