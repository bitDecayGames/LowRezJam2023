package entities;

import flixel.FlxObject;
import flixel.util.FlxTimer;
import progress.Collected;
import flixel.tweens.FlxTween;
import bitdecay.flixel.spacial.Cardinal;
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

	// Tune this to make the player feel more/less mobile
	private static inline var PLAYER_WEIGHT = 500;

	public var inControl:Bool = true;

	var groundedCastLeft:Bool = false;
	var groundedCastMiddle:Bool = false;
	var groundedCastRight:Bool = false;

	var topShape:echo.Shape.Shape;
	var bottomShape:echo.Shape.Shape;
	var groundCircle:echo.Shape.Shape;

	// if we are playing it in debug, make it harder for us. Be nice to players
	var COYOTE_TIME = #if debug 0.1 #else 0.2 #end;
	var JUMP_WINDOW = .5;
	var MIN_JUMP_WINDOW = 0.1;
	var INITIAL_JUMP_STRENGTH = -11.5 * Constants.BLOCK_SIZE;
	var MAX_JUMP_RELEASE_VELOCITY = -5 * Constants.BLOCK_SIZE;

	var MAX_VELOCITY = 15 * Constants.BLOCK_SIZE;

	var WALL_COLLIDE_SFX_THRESHOLD = 100;

	var previousVelocity:Vector2 = new Vector2(0, 0);

	// how many "Min jump windows" of duration we transition to full jump strength
	var JUMP_TRANSITION_MOD = 2;

	var bonkedHead = false;
	var jumping = false;
	var jumpHigherTimer = 0.0;

	var turnAccelBoost:Float = 3;
	var accel:Float = Constants.BLOCK_SIZE * 3125;
	var airAccel:Float = Constants.BLOCK_SIZE * 3125; // 1800
	var decel:Float = Constants.BLOCK_SIZE * 9;
	var maxSpeed:Float = Constants.BLOCK_SIZE * 4;
	var playerNum = 0;

	// set to true to run a one-time grounded check
	var checkGrounded = true;
	public var grounded = false;
	var unGroundedTime = 0.0;

	var tmp:FlxPoint = FlxPoint.get();
	var tmpAABB:AABB = AABB.get();
	var echoTmp:Vector2 = new Vector2(0, 0);

	var mixColors = false;

	var animState = new AnimationState();

	public function new(X:Float, Y:Float) {
		Y -= 20;
		super(X, Y, EMPTY);

		bottomShape = body.shapes[0];
		topShape = body.shapes[1];
		groundCircle = body.shapes[2];
	}

	override function configSprite() {
		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.player__json);

		for (f in animation.getByName(anims.run).frames) {
			// Thanks aseprite, but we want to manage these manually
			frames.frames[f].duration = 0;
		}
		animation.play(anims.stand);

		animation.callback = (name, frameNumber, frameIndex) -> {
			if (name == anims.run) {
				if (frameNumber == 4 || frameNumber == 10)  {
					FmodManager.PlaySoundOneShot(FmodSFX.PlayerStep);
				}
			}
		}

		// TODO: The deadzone on the camera seems to be 32 pix wide at the moment.
		// if we reduce this width the player has some "wiggle room" before camera starts
		// scrolling
		setSize(32, 32);
		offset.set(0, 2);
	}

	override function makeBody():Body {
		return this.add_body({
			x: x,
			y: y,
			max_velocity_x: maxSpeed,
			max_velocity_length: MAX_VELOCITY,
			drag_x: decel,
			mass: PLAYER_WEIGHT,
			shapes: [
				{
					type:RECT,
					width: 10,
					height: 20,
					offset_y: 10,
				},
				{
					type:RECT,
					width: 10,
					height: 20,
					offset_y: -5,
				},
				// collision snag helpers
				{
					type:CIRCLE,
					radius: 2,
					offset_y: 18.5
				}
				// Experimental side helpers to prevent snag on vertical walls
				// {
				// 	type:CIRCLE,
				// 	radius: 2,
				// 	offset_x: 3.5
				// },
				// {
				// 	type:CIRCLE,
				// 	radius: 2,
				// 	offset_x: -3.5
				// }
			]
		});
	}

	public function forceStand() {
		animation.play(anims.stand);
		body.velocity.x = 0;
	}

	@:access(echo.Shape)
	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		// only ignore this collision if the _OTHER_ shape is not solid
		if (data[0].sa.parent.object == this) {
			if (!data[0].sb.solid) {
				return;
			}
		} else if (data[0].sb.parent.object == this) {
			if (!data[0].sa.solid) {
				return;
			}
		}


		if (data[0].normal.y > 0) {
			checkGrounded = true;
		} else if (data[0].normal.y < 0) {
			bonkedHead = true;
			// TODO(SFX): head bonk
		}

		if (data[0].normal.x != 0 && previousVelocity.length > WALL_COLLIDE_SFX_THRESHOLD) {
			if (grounded) {
				// TODO(SFX): grounded wall smack
			} else {
				// TODO(SFX): airborne wall smack
			}
		}
	}

	@:access(echo.FlxEcho)
	public function transitionWalk(arrive:Bool, dir:Cardinal, cb:Void->Void) {
		playAnimIfNotAlready(anims.run);
		animation.curAnim.frameRate = 10;
		inControl = false;

		var transitionDistance = 72;
		// // // XXX: Make sure we are aligned with our physics body
		body.update_body_object();
		// body.active = false;
		var curPos = getPosition();
		var destPos = curPos.copyTo();
		switch(dir) {
			case E:
				if (arrive) {
					curPos.x -= transitionDistance;
				} else {
					destPos.x += transitionDistance;
				}
			case W:
				if (arrive) {
					curPos.x += transitionDistance;
				} else {
					destPos.x -= transitionDistance;	
				}
			default:
		}
		flipX = curPos.x < destPos.x;
		FlxTween.linearMotion(this, curPos.x, curPos.y, destPos.x, destPos.y, 1.5, {
			onComplete: (t) -> {
				inControl = true;
				body.active = true;
				body.set_position(x + origin.x, y + origin.y);
				cb();
			}
		});
	}

	override public function update(delta:Float) {
		super.update(delta);

		previousVelocity.set(body.velocity.x, body.velocity.y);

		animState.reset();

		FlxG.watch.addQuick("Player anim: ", '${animation.curAnim.name}:${animation.curAnim.curFrame+1}/${animation.curAnim.numFrames}');
		FlxG.watch.addQuick("Player grounded: ", '${grounded}');

		if (inControl) {
			handleInput(delta);
			updateCurrentAnimation();
		}

		DebugDraw.ME.drawWorldCircle(PlayState.ME.dbgCam, body.x, body.y, 1, PLAYER, FlxColor.BLUE);

		#if debug
		if (FlxG.keys.justPressed.ONE) {
			Collected.unlockBlue();
		}
		if (FlxG.keys.justPressed.TWO) {
			Collected.unlockYellow();
		}
		if (FlxG.keys.justPressed.THREE) {
			Collected.unlockRed();
		}
		#end
	}

	function handleInput(delta:Float) {
		var inputDir = InputCalcuator.getInputCardinal(playerNum);
		if (inputDir != NONE) {
			inputDir.asVector(tmp);
			if (tmp.x != 0 && grounded) {
				if (!SimpleController.pressed(DOWN)) {
					animState.add(RUNNING);
					body.acceleration.x = accel * (tmp.x < 0 ? -1 : 1);
				} else {
					// can't hold down and run
					body.acceleration.x = 0;
				}
			} else if (tmp.x != 0 && !grounded) {
				body.acceleration.x = airAccel * (tmp.x < 0 ? -1 : 1);
			} else {
				body.acceleration.x = 0;
			}

			if (body.velocity.x > 0 && body.acceleration.x < 0 || body.velocity.x < 0 && body.acceleration.x > 0) {
				body.acceleration.x *= turnAccelBoost;
			}

			if (body.acceleration.x != 0) {
				flipX = body.acceleration.x > 0;
			}
		} else {
			body.acceleration.x = 0;

			if (Math.abs(body.velocity.x) < 5) {
				body.velocity.x = 0;
			}
		}

		if (body.velocity.x == 0) {
			if (mixColors) {
				removeColor(RED);
			}
		} else {
			if (mixColors) {
				addColorIfUnlocked(RED);
			}
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
			unGroundedTime = Math.min(unGroundedTime + delta, COYOTE_TIME);

			if (unGroundedTime < COYOTE_TIME) {
				DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam,
					body.x - 5,
					body.y - 25,
					body.x + 5 - (unGroundedTime / COYOTE_TIME * 10),
					body.y - 25, PLAYER, FlxColor.LIME);
			}
		} else {
			unGroundedTime = 0.0;
		}

		if (jumping) {
			jumpHigherTimer = Math.max(0, jumpHigherTimer - delta);
			FlxG.watch.addQuick('jump timer: ', jumpHigherTimer);
			if (!SimpleController.pressed(A) || bonkedHead) {
				jumping = false;
				body.velocity.y = Math.max(body.velocity.y, MAX_JUMP_RELEASE_VELOCITY);
			}
		}

		var velScaler = 20;
		var color = jumping ? FlxColor.CYAN : FlxColor.MAGENTA;

		FlxG.watch.addQuick('Player y velocity: ', body.velocity.y);
		DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam,
			body.x - 15,
			body.y,
			body.x - 15,
			body.y + (body.velocity.y / 20),
			PLAYER,
			color);
		DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam,
			body.x - 20,
			body.y + INITIAL_JUMP_STRENGTH / velScaler,
			body.x - 10,
			body.y + INITIAL_JUMP_STRENGTH / velScaler,
			PLAYER,
			FlxColor.ORANGE);
		DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam,
			body.x - 20,
			body.y + MAX_JUMP_RELEASE_VELOCITY / velScaler,
			body.x - 10,
			body.y + MAX_JUMP_RELEASE_VELOCITY / velScaler,
			PLAYER,
			FlxColor.RED);
		DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam,
			body.x - 23,
			body.y,
			body.x - 7,
			body.y,
			PLAYER,
			FlxColor.GRAY);
		DebugDraw.ME.drawWorldRect(PlayState.ME.dbgCam,
			body.x - 23,
			body.y - MAX_VELOCITY / velScaler,
			13,
			MAX_VELOCITY / velScaler * 2,
			PLAYER,
			FlxColor.GRAY);


		if ((grounded || (unGroundedTime < COYOTE_TIME)) && SimpleController.just_pressed(A)) {
			FmodManager.PlaySoundOneShot(FmodSFX.PlayerJump4);
			y--;
			body.velocity.y = INITIAL_JUMP_STRENGTH;
			unGroundedTime = COYOTE_TIME;
			grounded = false;
			jumpHigherTimer = JUMP_WINDOW;
			jumping = true;
			bonkedHead = false;
		}

		// TODO: Need to prevent running (x-accel) when crouching
		if (SimpleController.pressed(DOWN)) {
			animState.add(CROUCHED);
			topShape.solid = false;
			if (mixColors) {
				addColorIfUnlocked(YELLOW);
			}
		} else {
			topShape.solid = true;
			if (mixColors) {
				removeColor(YELLOW);
			}
		}
		
		body.bounds(tmpAABB);

		groundedCastLeft = false;
		groundedCastMiddle = false;
		groundedCastRight = false;
		
		var rayChecksPassed = 0;
		echoTmp.set(tmpAABB.min_x, tmpAABB.max_y - 2);
		var groundedCast = Line.get_from_vector(echoTmp, 90, 5);
		var intersects = groundedCast.linecast_all(FlxEcho.get_group_bodies(PlayState.ME.objects));
		DebugDraw.ME.drawWorldLine(PlayState.ME.dbgCam, echoTmp.x, echoTmp.y, groundedCast.end.x, groundedCast.end.y, DebugLayers.RAYCAST, intersects.length >= 1 ? FlxColor.MAGENTA : FlxColor.LIME);
		groundedCast.put();
		if (intersects.length >= 1) {
			rayChecksPassed++;
			groundedCastLeft = true;
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
			groundedCastMiddle = true;
		}
		for (i in intersectsMiddle) {
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
			groundedCastRight = true;
		}
		for (i in intersectsRight) {
			i.put();
		}

		// Here for better ground feel
		// if (groundedCastMiddle && (!groundedCastLeft || !groundedCastRight)) {
		// 	groundCircle.solid = false;
		// } else {
		// 	groundCircle.solid = true;
		// }

		groundCircle.solid = groundedCastMiddle || (!groundedCastLeft && !groundedCastRight);



		// this cast is originating within the player, so it will always give back at least one
		if (rayChecksPassed >= 1) {
			if (checkGrounded) {
				checkGrounded = false;
				if(grounded == false) {
					FmodManager.PlaySoundOneShot(FmodSFX.PlayerLand1);
				}
				grounded = true;
				if (mixColors) {
					removeColor(BLUE);
				}
			}
		} else if (!groundedCastLeft && !groundedCastMiddle && !groundedCastRight) {
			checkGrounded = false;
			grounded = false;
			if (mixColors) {
				addColorIfUnlocked(BLUE);
			}
		}

		if (grounded) {
			animState.add(GROUNDED);
		}

		if (!mixColors) {
			var tmpColor = interactColor;

			interactColor = EMPTY;

			// moving means red
			if (Math.abs(body.velocity.x) > 0 || (SimpleController.pressed(LEFT) || SimpleController.pressed(RIGHT))) {
				if (Collected.has(RED)) {
					interactColor = RED;
				}
			}

			// airborn blue takes priority over red
			if (!grounded) {
				if (Collected.has(BLUE)) {
					interactColor = BLUE;
				}
			}

			// crouching  takes priority over blue and red
			if (SimpleController.pressed(DOWN)) {
				if (Collected.has(YELLOW)) {
					interactColor = YELLOW;
				}
			}

			if (interactColor != tmpColor) {
				lastColor = tmpColor;
				colorTime = 0.0;
			}
		}
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
						playAnimIfNotAlready(anims.slide);
					} else {
						FmodManager.PlaySoundOneShot(FmodSFX.PlayerSkidShort);
						playAnimIfNotAlready(anims.skid);
					}
				} else {
					// if (animState.has(CROUCHED)) {
					// 	animation.play('crawl');
					// }
					playAnimIfNotAlready(anims.run);
				}
			} else { 
				if (animState.has(CROUCHED)) {
					if (body.velocity.x != 0) {
						playAnimIfNotAlready(anims.slide);
					} else {
						playAnimIfNotAlready(anims.crouch);
					}
				} else {
					if (body.velocity.x != 0) {
						// FmodManager.PlaySoundOneShot(FmodSFX.PlayerSkidShort);
						playAnimIfNotAlready(anims.run);
					} else {
						playAnimIfNotAlready(anims.stand);
					}
				}
			}
		} else {
			if (animState.has(CROUCHED)) {
				playAnimIfNotAlready(anims.jumpCrouch);
			} else {
				if (body.velocity.y > 0) {
					playAnimIfNotAlready(anims.fall);
				} else {
					playAnimIfNotAlready(anims.jump);
				}
			}
		}

		// FlxG.watch.addQuick("Player Anim: ", animation.curAnim.name);
	}

	function playAnimIfNotAlready(name:String) {
		if (animation.curAnim == null || animation.curAnim.name != name) {
			animation.play(name, true);
		}
	}

	public function beginDie() {
		inControl = false;
		body.velocity.set(0, 0);
		body.active = false;
		FmodManager.PlaySoundOneShot(FmodSFX.PlayerDieHit);
		new FlxTimer().start(.25, (t) -> {
			FmodManager.PlaySoundOneShot(FmodSFX.PlayerDieSwell4);
			playAnimIfNotAlready(anims.death);
		});
	}

	function addColorIfUnlocked(c:Color) {
		if (Collected.has(c)) {
			addColor(c);
		}
	}

	function setColorIfUnlocked(c:Color) {
		if (Collected.has(c)) {
			interactColor = c;
		}
	}
}
