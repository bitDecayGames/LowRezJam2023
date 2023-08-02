package entities;

import echo.Body;
import echo.data.Data.CollisionData;
import debug.DebugLayers;
import bitdecay.flixel.debug.DebugDraw;
import states.PlayState;
import echo.Line;
import collision.Color;
import collision.ColorCollideSprite;
import flixel.FlxG;
import echo.math.Vector2;
import collision.Constants;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.FlxSprite;

import input.InputCalcuator;
import input.SimpleController;
import loaders.Aseprite;
import loaders.AsepriteMacros;

using echo.FlxEcho;

class Player extends ColorCollideSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/player.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/characters/player.json");
	public static var eventData = AsepriteMacros.frameUserData("assets/aseprite/characters/player.json", "Layer 1");

	var body:echo.Body;

	var JUMP_STRENGTH = -10 * Constants.BLOCK_SIZE;
	var accel:Float = Constants.BLOCK_SIZE * 3125;
	var airAccel:Float = Constants.BLOCK_SIZE * 1800;
	var decel:Float = Constants.BLOCK_SIZE * 9;
	var maxSpeed:Float = Constants.BLOCK_SIZE * 5;
	var playerNum = 0;

	// set to true to run a one-time grounded check
	var checkGrounded = true;
	var grounded = false;
	var unGroundedTime = 0.0;
	var coyoteTime = 0.2;

	var tmp:FlxPoint = FlxPoint.get();
	var echoTmp:Vector2 = new Vector2(0, 0);

	public function new(X:Float, Y:Float) {
		super(X, Y, FlxColor.WHITE);
		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		// Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		// animation.play(anims.right);
		// animation.callback = (anim, frame, index) -> {
		// 	if (eventData.exists(index)) {
		// 		// trace('frame $index has data ${eventData.get(index)}');
		// 	}
		// };

		loadGraphic(AssetPaths.run_sheet__png, true, 32, 48);
		animation.add('run', [ for (i in 0...20) i]);
		setSize(16, 32);
		offset.set(0, 10);
		color = FlxColor.WHITE;

		body = this.add_body({
			x: X,
			y: Y,
			max_velocity_x: maxSpeed,
			drag_x: decel,
			shape: {
				type:CIRCLE,
				radius: 8,
				// type: RECT,
				// width: 16, // we should be able to pull this from the aseprite file, maybe?
				// height: 32,
			}
		});
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		trace('handling player enter');
		super.handleEnter(other, data);

		if (data[0].normal.y > 0) {
			checkGrounded = true;
		}
	}

	override public function update(delta:Float) {
		super.update(delta);

		var inputDir = InputCalcuator.getInputCardinal(playerNum);
		if (inputDir != NONE) {
			inputDir.asVector(tmp);
			if (tmp.x != 0) {
				if (grounded) {
					body.acceleration.x = accel * (tmp.x < 0 ? -1 : 1);
				} else {
					body.acceleration.x = airAccel * (tmp.x < 0 ? -1 : 1);
				}
				animation.play('run');
				flipX = body.acceleration.x > 0;
			}
		} else {
			body.acceleration.x = 0;
			
			if (Math.abs(body.velocity.x) < 5) {
				body.velocity.x = 0;
				animation.stop();
				animation.frameIndex = 4;
			}
		}

		if (animation.curAnim != null) {
			animation.curAnim.frameRate = FlxMath.minInt(Std.int(Math.abs(body.velocity.x) / maxSpeed * 30), 30);
			FlxG.watch.addQuick("Player frame rate: ", animation.curAnim.frameRate);
		}

		if (!grounded) {
			unGroundedTime = Math.min(unGroundedTime + delta, coyoteTime);
		}

		if ((grounded || (unGroundedTime < coyoteTime)) && SimpleController.just_pressed(Button.A, playerNum)) {
			y--;
			body.velocity.y = JUMP_STRENGTH;
		}
		
		var groundedCast = Line.get_from_vector(body.get_position(echoTmp), 90, 15);
		var intersects = groundedCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.objects), FlxEcho.instance.world);
		DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam, echoTmp.x, echoTmp.y, groundedCast.end.x, groundedCast.end.y, DebugLayers.RAYCAST, intersects.length > 1 ? FlxColor.MAGENTA : FlxColor.LIME);
		
		body.get_position(echoTmp);
		echoTmp.x += width/2.5;
		groundedCast = Line.get_from_vector(echoTmp, 90, 15);
		var intersectsRight = groundedCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.objects), FlxEcho.instance.world);
		DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam, echoTmp.x, echoTmp.y, groundedCast.end.x, groundedCast.end.y, DebugLayers.RAYCAST, intersectsRight.length > 1 ? FlxColor.MAGENTA : FlxColor.LIME);
		
		body.get_position(echoTmp);
		echoTmp.x -= width/2.5;
		groundedCast = Line.get_from_vector(echoTmp, 90, 15);
		var intersectsLeft = groundedCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.objects), FlxEcho.instance.world);
		DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam, echoTmp.x, echoTmp.y, groundedCast.end.x, groundedCast.end.y, DebugLayers.RAYCAST, intersectsLeft.length > 1 ? FlxColor.MAGENTA : FlxColor.LIME);
		
		// this cast is originating within the player, so it will always give back at least one
		if (intersects.length > 1) {
			if (checkGrounded) {
				checkGrounded = false;
				grounded = true;
				color = cast Color.WHITE;	
			}
		} else if (intersects.length <= 1 && intersectsLeft.length <= 1 && intersectsRight.length <= 1) {
			checkGrounded = false;
			grounded = false;
			color = cast Color.BLUE;
		}
	}
}
