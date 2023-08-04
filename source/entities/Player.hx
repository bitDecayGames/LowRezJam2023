package entities;

import echo.util.AABB;
import animation.AnimationState;
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
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

import input.InputCalcuator;
import input.SimpleController;
import loaders.Aseprite;
import loaders.AsepriteMacros;

using echo.FlxEcho;

class Player extends ColorCollideSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/player.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/characters/player.json");
	// public static var eventData = AsepriteMacros.frameUserData("assets/aseprite/characters/player.json", "Layer 1");

	public var body:echo.Body;
	var topShape:echo.Shape.Shape;
	var bottomShape:echo.Shape.Shape;

	var JUMP_STRENGTH = -10 * Constants.BLOCK_SIZE;
	var turnAccelBoost:Float = 3;
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
	var tmpAABB:AABB = AABB.get();
	var echoTmp:Vector2 = new Vector2(0, 0);

	var animState = new AnimationState();

	public function new(X:Float, Y:Float) {
		super(X, Y, EMPTY);

		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		// animation.
		for (f in frames.frames) {
			// Thanks aseprite, but we want to manage these manually
			f.duration = 0;
		}
		animation.play(anims.stand);
		// animation.callback = (anim, frame, index) -> {
			// if (eventData.exists(index)) {
				// trace('frame $index has data ${eventData.get(index)}');
			// }
		// };

		// loadGraphic(AssetPaths.run_sheet__png, true, 32, 48);
		// animation.add('run', [ for (i in 0...20) i]);
		// animation.add('crouch', [20]);
		// animation.add('skid', [21]);
		// animation.add('jump', [22]);
		// animation.add('fall', [23]);
		// animation.add('slide', [24]);
		// animation.add('stand', [25]);
		setSize(16, 32);
		offset.set(0, 16);

		body = this.add_body({
			x: X,
			y: Y,
			max_velocity_x: maxSpeed,
			drag_x: decel,
			shapes: [
				{
					type:CIRCLE,
					radius: 4,
					offset_x: -4
				},
				{
					type:CIRCLE,
					radius: 4,
					offset_x: 4
				},
				{
					type:CIRCLE,
					offset_y: -16,
					radius: 8,
				}
			]
		});
		bottomShape = body.shapes[0];
		topShape = body.shapes[2];
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		// This likely needs to be done safer
		if (!data[0].sa.solid || !data[0].sb.solid) {
			return;
		}

		if (data[0].normal.y > 0) {
			checkGrounded = true;
		}
	}

	override public function update(delta:Float) {
		super.update(delta);

		animState.reset();

		var inputDir = InputCalcuator.getInputCardinal(playerNum);
		if (inputDir != NONE) {
			inputDir.asVector(tmp);
			if (tmp.x != 0) {
				animState.add(RUNNING);

				if (grounded) {
					body.acceleration.x = accel * (tmp.x < 0 ? -1 : 1);
				} else {
					body.acceleration.x = airAccel * (tmp.x < 0 ? -1 : 1);
				}
				if (body.velocity.x > 0 && body.acceleration.x < 0 || body.velocity.x < 0 && body.acceleration.x > 0) {
					body.acceleration.x *= turnAccelBoost;
				}
				flipX = body.acceleration.x > 0;
			} else {
				body.acceleration.x = 0;
			}
		} else {
			body.acceleration.x = 0;

			if (Math.abs(body.velocity.x) < 5) {
				body.velocity.x = 0;
			}
		}

		if (body.velocity.x == 0) {
			removeColor(RED);
		} else {
			addColor(RED);
		}

		if (body.acceleration.x > 0) {
			animState.add(ACCEL_RIGHT);
		} else if (body.acceleration.x < 0) {
			animState.add(ACCEL_LEFT);
		}

		FlxG.watch.addQuick("Player X Accel: ", body.acceleration.x);

		if (animation.curAnim != null) {
			animation.curAnim.frameRate = FlxMath.minInt(Std.int(Math.abs(body.velocity.x) / maxSpeed * 30), 30);
			FlxG.watch.addQuick("Player frame rate: ", animation.curAnim.frameRate);
		}

		if (!grounded) {
			unGroundedTime = Math.min(unGroundedTime + delta, coyoteTime);
		}

		if ((grounded || (unGroundedTime < coyoteTime)) && SimpleController.just_pressed(A)) {
			y--;
			body.velocity.y = JUMP_STRENGTH;
		}

		// TODO: Need to prevent running (x-accel) when crouching
		if (SimpleController.pressed(DOWN)) {
			animState.add(CROUCHED);
			topShape.solid = false;
			addColor(YELLOW);
		} else {
			topShape.solid = true;
			removeColor(YELLOW);
		}
		
		body.bounds(tmpAABB);
		

		var rayChecksPassed = 0;
		echoTmp.set(tmpAABB.min_x, tmpAABB.max_y - 2);
		var groundedCast = Line.get_from_vector(echoTmp, 90, 5);
		var intersects = groundedCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.objects));
		DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam, echoTmp.x, echoTmp.y, groundedCast.end.x, groundedCast.end.y, DebugLayers.RAYCAST, intersects.length >= 1 ? FlxColor.MAGENTA : FlxColor.LIME);
		groundedCast.put();
		if (intersects.length >= 1) {
			rayChecksPassed++;
		}
		for (i in intersects) {
			i.put();
		}
		
		echoTmp.set(tmpAABB.min_x, tmpAABB.max_y - 2);
		echoTmp.x += tmpAABB.width/2;
		groundedCast = Line.get_from_vector(echoTmp, 90, 5);
		var intersectsMiddle = groundedCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.objects));
		DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam, echoTmp.x, echoTmp.y, groundedCast.end.x, groundedCast.end.y, DebugLayers.RAYCAST, intersectsMiddle.length >= 1 ? FlxColor.MAGENTA : FlxColor.LIME);
		groundedCast.put();
		if (intersectsMiddle.length >= 1) {
			rayChecksPassed++;
		}
		for (i in intersects) {
			i.put();
		}

		echoTmp.set(tmpAABB.min_x, tmpAABB.max_y - 2);
		echoTmp.x += tmpAABB.width;
		groundedCast = Line.get_from_vector(echoTmp, 90, 5);
		var intersectsRight = groundedCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.objects));
		DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam, echoTmp.x, echoTmp.y, groundedCast.end.x, groundedCast.end.y, DebugLayers.RAYCAST, intersectsRight.length >= 1 ? FlxColor.MAGENTA : FlxColor.LIME);
		groundedCast.put();
		if (intersectsRight.length >= 1) {
			rayChecksPassed++;
		}
		for (i in intersects) {
			i.put();
		}

		// this cast is originating within the player, so it will always give back at least one
		if (rayChecksPassed >= 1) {
			if (checkGrounded) {
				checkGrounded = false;
				grounded = true;
				removeColor(BLUE);
			}
		} else if (intersects.length <= 1 && intersectsRight.length <= 1 && intersectsMiddle.length <= 1) {
			checkGrounded = false;
			grounded = false;
			addColor(BLUE);
		}

		if (grounded) {
			animState.add(GROUNDED);
		}

		updateCurrentAnimation();

		DebugDraw.ME.drawCameraRect(PlayState.ME.dbgCam, 0, 0, 10,10, GENERAL, interactColor);
	}

	function updateCurrentAnimation() {
		if (body.velocity.x > 0) {
			flipX = true;
		} else if (body.velocity.x < 0) {
			flipX = false;
		}

		if (animState.has(GROUNDED)) {
			if (animState.has(RUNNING)) {
				if ((animState.has(ACCEL_LEFT) && body.velocity.x > 0) || (animState.has(ACCEL_RIGHT) && body.velocity.x < 0)) {
					if (animState.has(CROUCHED)) {
						// animation.play('slide');
					} else {
						// animation.play('skid');
					}
				} else {
					// if (animState.has(CROUCHED)) {
					// 	animation.play('crawl');
					// }
					animation.play(anims.run);
				}
			} else { 
				if (animState.has(CROUCHED)) {
					if (body.velocity.x != 0) {
						// animation.play('slide');
					} else {
						// animation.play('crouch');
					}
				} else {
					if (body.velocity.x != 0) {
						// animation.play('skid');
					} else {
						animation.play(anims.stand);
					}
				}
			}
		} else {
			if (body.velocity.y > 0) {
				// animation.play('fall');
			} else {
				// animation.play('jump');
			}
		}

		// FlxG.watch.addQuick("Player Anim: ", animation.curAnim.name);
	}
}
