package states.substate;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import collision.Color;
import entities.DummyPlayer;
import flixel.util.FlxColor;
import flixel.FlxG;
import entities.UnlockParticle;
import flixel.FlxSubState;

using bitdecay.flixel.extensions.FlxObjectExt;

class UpgradeCutscene extends FlxSubState {
	var finishCb:Void->Void = null;

	var upgradeColor:Color;

	var screenPoint:FlxPoint;
	var offset = FlxPoint.get(2, -2);

	var power:UnlockParticle;
	var player:DummyPlayer;

	var deltaMod = 1.0;
	var flipped = false;

	public function new(flip:Bool, playerPoint:FlxPoint, upgradeColor:Color, ?cb:Void->Void) {
		super();
		flipped = flip;
		screenPoint = offset.copyTo().addPoint(playerPoint);
		this.upgradeColor = upgradeColor;
		finishCb = cb;

		camera = PlayState.ME.objectCam;
	}

	override function create() {
		super.create();

		PlayState.ME.objectCam.fade(FlxColor.BLACK, .3, true);

		var bg = new FlxSprite();
		bg.makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width + 32, FlxG.height + 32);
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		player = new DummyPlayer(0,0);
		player.scrollFactor.set();
		player.setPositionMidpoint(screenPoint.x, screenPoint.y);
		player.flipX = flipped;
		add(player);

		var onDone:Void->Void = done;
		var onHit:Void->Void = null;
		if (upgradeColor == ALL) {
			player.emitterCB = (e) -> {
				deltaMod = 0.25;
				var playerMiddle = player.getGraphicMidpoint();
				for (emitter in e) {
					// XXX: Can't set the scroll factor on the emitter... so just move it far enough to be in the right spot
					emitter.setPosition(playerMiddle.x + PlayState.ME.objectCam.scroll.x, playerMiddle.y + PlayState.ME.objectCam.scroll.y);
					add(emitter);
				}
			};
			onDone = null;
			onHit = () -> {
				player.animation.stop();
				new FlxTimer().start(2, (t1) -> {
					player.explode();
					new FlxTimer().start(8, (t) -> {done();});
				});
			}
		}

		power = new UnlockParticle(0,0, onDone, () -> {
			PlayState.ME.objectCam.flash(cast upgradeColor, 0.1);
			PlayState.ME.objectCam.shake(0.01, 0.4);
			player.color = cast upgradeColor;
			player.addColor(upgradeColor);
		}, onHit);
		power.flipX = flipped;
		power.color = cast upgradeColor;
		power.scrollFactor.set();
		power.setPositionMidpoint(screenPoint.x, screenPoint.y);

		add(power);
	}

	function done() {
		player.removeColor(upgradeColor);
		new FlxTimer().start(0.75, (timer) -> {
			switch(upgradeColor) {
				case BLUE:
					demoJump();
				case YELLOW:
					demoCrouch();
				case RED:
					demoRun();
				case ALL:
					doWrapUp();
				default:
			}
		});
	}

	function demoJump() {
		player.addColor(BLUE);
		animatePlayerJump(() -> {
			player.land();
			player.removeColor(BLUE);
			doWrapUp();
		}, player.jump, player.fall);
	}

	function demoCrouch() {
		player.crouch();
		player.addColor(YELLOW);
		new FlxTimer().start(0.75, (t1) -> {
			player.uncrouch();
			player.removeColor(YELLOW);
			new FlxTimer().start(0.75, (t2) -> {
				new FlxTimer().start(0.25, (t3) -> {
					player.jumpCrouch();
					player.addColor(YELLOW);
				});
				new FlxTimer().start(.75, (t4) -> {
					player.unJumpCrouch();
					player.removeColor(YELLOW);
				});
				animatePlayerJump(() -> {
					player.land();
					new FlxTimer().start(0.75, (t4) -> {
						player.crouch();
						player.addColor(YELLOW);
						new FlxTimer().start(0.75, (t5) -> {
							FmodManager.PlaySoundOneShot(FmodSFX.PlayerJump4);
							animatePlayerJump(() -> {
								FmodManager.PlaySoundOneShot(FmodSFX.PlayerLand1);
								new FlxTimer().start(0.75, (t6) -> {
									player.uncrouch();
									player.removeColor(YELLOW);
									doWrapUp();
								});
							}, null, null);
						});
					});
				}, player.jump, null);
			});
		});
	}

	function demoRun() {
		player.run();
		player.addColor(RED);
		new FlxTimer().start(2, (t) -> {
			player.stopRun();
			new FlxTimer().start(0.3, (t2) -> {
				player.removeColor(RED);
				player.stand();
				doWrapUp();
			});
		});
	}

	function animatePlayerJump(complete:Void->Void, riseAnim:Void->Void, fallAnim:Void->Void) {
		var startY = player.y;
		if (riseAnim != null) riseAnim();
		FlxTween.tween(player, {y: player.y - 64}, 0.5, {
			ease: FlxEase.sineOut,
			onComplete: (t) -> {
				if (fallAnim != null) fallAnim();
				FlxTween.tween(player, {y: startY}, 0.5, {
					ease: FlxEase.sineIn,
					onComplete: (t2) -> {
						complete();
					}
				});
			}
		});
	}

	function doWrapUp() {
		new FlxTimer().start(1, (t3) -> {
			PlayState.ME.objectCam.fade(FlxColor.BLACK, 0.5, () -> {
				power.kill();
				player.kill();
				bgColor = FlxColor.TRANSPARENT;
				if (finishCb != null) {
					finishCb();
				}
			});
		});
	}

	override function update(elapsed:Float) {
		super.update(elapsed * deltaMod);
	}
}