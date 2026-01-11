package config;

import io.newgrounds.NGLite.LoginOutcome;
import haxe.Timer;
import flixel.util.FlxSignal;
import io.newgrounds.objects.Score;
import flixel.FlxG;
import io.newgrounds.objects.SaveSlot;
import io.newgrounds.objects.SaveSlot.SaveSlotOutcome;
import states.PlayState;
import helpers.Storage;
import flixel.util.FlxStringUtil;
import io.newgrounds.Call.CallError;
import io.newgrounds.objects.events.Outcome;
import io.newgrounds.NG;

// Lovingly adapted from GeoKureli's repo here
// https://github.com/Geokureli/Newgrounds/blob/master/test/openfl-swf/Source/io/newgrounds/test/SimpleTest.hx
class Newgrounds {

	public static inline var SCOREBOARD_FULL_CLEAR = 15468;

	public static var rushScoreSignal(default, null) = new FlxTypedSignal<Void->Void>();

	public static var slotLoadedSignal(default, null) = new FlxTypedSignal<Int->Void>();
	public static var loginSignal(default, null) = new FlxSignal();

	// Returns true if Newgrounds was properly configured, false otherwise
	public static function init():Bool {
		if (FlxStringUtil.isNullOrEmpty(Env.getNGAppID())){
			#if debug
			trace('no NG app id found. Skipping NG init');
			#end

			NG.create();
			return false;
		}

		var debug = false;
		#if debug
		trace("connecting to newgrounds");

		// Use debug so medal unlocks and scoreboards reset after this session
		debug = true;
		#end

		NG.createAndCheckSession(Env.getNGAppID(), debug);
		if (debug) {
			NG.core.verbose = true;
		}

		NG.core.setupEncryption(Env.getNGEncryptKey(), AES_128, BASE_64);

		if (NG.core.attemptingLogin) {
			/* a session_id was found in the loadervars, this means the user is playing on newgrounds.com
			 * and we should login shortly. lets wait for that to happen
			 */
			trace('existing session found, waiting for login to complete');
			NG.core.onLogin.add(onNGLogin);
		}
		return true;
	}

	public static function requestLogin(?onSuccess:Void->Void, ?onCancel:Void->Void) {
		if (!NG.core.loggedIn) {
			/* They are NOT playing on newgrounds.com, no session id was found. We must start one manually, if we want to.
			 * Note: This will cause a new browser window to pop up where they can log in to newgrounds
			 */
			NG.core.requestLogin((r:LoginOutcome)-> {
				switch (r) {
					case FAIL(error):
						onCancel();
					case SUCCESS:
						onSuccess();
						onNGLogin();
				}
			});
		} else {
			trace('requested login while already logged in. Ignoring');
		}
	}

	static function onNGLogin() {
		#if debug
		trace ('logged in! user:${NG.core.user.name}');
		#end

		loginSignal.dispatch();

		NG.core.scoreBoards.loadList(onNGBoardsFetch);
		NG.core.medals.loadList(onNGMedalsFetch);
		//NG.core.saveSlots.loadList(onNGSaveSlotsFetch);
	}

	static function onNGBoardsFetch(outcome:Outcome<CallError>) {
		// TODO: Do we care if this call fails? We don't actually need any board info within the game

		#if debug
		outcome.assert('Error loading score boards:');

		// Reading scoreboard info
		for (id in NG.core.scoreBoards.keys()) {
			var board = NG.core.scoreBoards[id];
			trace('loaded scoreboard id:$id, name:${board.name}');
		}
		#end
	}

	static function onNGMedalsFetch(outcome:Outcome<CallError>) {
		// #if debug
		// outcome.assert('Error loading medals:');

		// // Reading scoreboard info
		// for (id in NG.core.medals.keys()) {
		// 	var medal = NG.core.medals[id];
		// 	trace('loaded medal id:$id, name:${medal.name}');
		// 	trace('   medal img: ${medal.icon}');
		// }
		// #end

		// switch (outcome) {
		// 	case FAIL(error):
		// 		// TODO: Handle error
		// 		trace('failed to fetch medals: $error');
		// 	case SUCCESS:
		// 		Storage.syncNGMedals(NG.core.medals);
		// 		#if (ngdebug || debug)
		// 		Achievements.verify(NG.core.medals);
		// 		#end
		// 		if (PlayState.ME != null) {
		// 			// TODO: update achievements
		// 			// TODO: This could be updated mid-game if the player waits to login. We may need to provide a way
		// 			//      to let others know so the list in-game can be updated.
		// 		}
		// }
	}

	// static function onNGSaveSlotsFetch(outcome:Outcome<CallError>) {
	// 	#if debug
	// 	outcome.assert('Error loading save slots:');

	// 	for (id in NG.core.saveSlots.keys()) {
	// 		var slot = NG.core.saveSlots[id];
	// 		if (slot.url != null) {
	// 			trace('loading save slot id:$id, name:${slot.datetime}');
	// 			slot.load((outcome:SaveSlotOutcome) -> {
	// 				switch (outcome) {
	// 					case FAIL(error):
	// 						// TODO: Handle error
	// 						trace('failed to load slot: $slot.id: $error');
	// 					case SUCCESS(contents):
	// 						trace('    slot contents:${contents}');
	// 				}
	// 			});
	// 		} else {
	// 			trace('save slot "${slot.id}" has no data');
	// 		}
	// 	}
	// 	#end

	// 	switch (outcome) {
	// 		case FAIL(error):
	// 			// TODO: Handle error
	// 			trace('failed to fetch save slots: $error');
	// 		case SUCCESS:
	// 			for (i in 0...NG.core.saveSlots.length) {
	// 				if (i > 2) {
	// 					// we only support a max of 3 slots at the moment
	// 					break;
	// 				}
	// 				// These come 1-based
	// 				var slot = NG.core.saveSlots[i+1];
	// 				if (slot.url != null) {
	// 					slot.load(onSingleSlotLoaded(slot));
	// 				} else {
	// 					#if debug
	// 					trace('save slot "${slot.id}" has no data');
	// 					#end
	// 					Storage.loadSlotFromNG(slot);
	// 					slotLoadedSignal.dispatch(slot.id-1);
	// 				}
	// 			}
	// 	}
	// }

	// private static function onSingleSlotLoaded(slot:SaveSlot):(SaveSlotOutcome -> Void) {
	// 	return (outcome) -> {
	// 		switch (outcome) {
	// 			case FAIL(error):
	// 				trace('failed to load slot: $error');
	// 			case SUCCESS(contents):
	// 				Storage.loadSlotFromNG(slot);
	// 				slotLoadedSignal.dispatch(slot.id-1);
	// 		}
	// 	}
	// }

	static function onNGScoresFetch(id:Int) {
		return () -> {
			for (score in NG.core.scoreBoards[id].scores)
				trace('board: \'$id\' score loaded user:${score.user.name}, score:${score.formattedValue}');
		}
	}

	public static function reportScore(time:Float) {
		if (NG.core == null || !NG.core.loggedIn) {
			return;
		}

		var boardId = Newgrounds.SCOREBOARD_FULL_CLEAR;
		var board = NG.core.scoreBoards[boardId];

		board.postScore(Math.round(time * 1000));

		// add an update listener so we know when we get the new scores
		// board.onUpdate.add(onNGScoresFetch(boardId));
		// board.requestScores(10);
		// more info on scores --- http://www.newgrounds.io/help/components/#scoreboard-getscores
	}

	// public static function reportMedal(m:NGMedal) {
	// 	if (NG.core == null || !NG.core.loggedIn) {
	// 		return;
	// 	}

	// 	var medal = NG.core.medals[m];

	// 	if (medal.unlocked) {
	// 		#if debug
	// 		trace('unlock medal is already unlocked: ${medal.id} - ${medal.name}');
	// 		#end
	// 		return;
	// 	}

	// 	#if debug
	// 	trace('unlock medal: ${medal.id} - ${medal.name}');
	// 	#end

	// 	#if ngdebug
	// 	medal.sendDebugUnlock();
	// 	#else
	// 	medal.sendUnlock();
	// 	#end
	// }

	// public static function reportChallengeRush(time:Float) {
	// 	if (NG.core == null || !NG.core.loggedIn) {
	// 		// save this for a login attempt later
	// 		failedRushSubmission = time;
	// 		return;
	// 	}

	// 	#if debug
	// 	trace('challenge rush time: ${time}');
	// 	#end

	// 	var board = NG.core.scoreBoards[SCOREBOARD_CHALLENGE_RUSH];
	// 	board.postScore(Math.round(time * 1000));
	// 	// give a short delay to ensure our score was posted
	// 	Timer.delay(() -> {
	// 		board.requestScores(10, 0, ALL, null, null, null, updateAllTimeCache);
	// 	}, 1000);
	// }

	// private static function updateAllTimeCache(outcome:Outcome<CallError>) {
	// 	switch(outcome) {
	// 		case SUCCESS:
	// 			FlxG.log.notice('all-time scores successfully retrieved');
	// 			updateCachedScores(false);
	// 			if (NG.core.loggedIn) {
	// 				// only update social if we are logged in
	// 				rushScoreSignal.dispatch();
	// 				var board = NG.core.scoreBoards[SCOREBOARD_CHALLENGE_RUSH];
	// 				board.requestScores(10, 0, ALL, true, null, null, updateSocialCache);
	// 			}
	// 		case FAIL(error):
	// 			FlxG.log.warn('scores failed to be retrieved: ${error}');
	// 			// TODO: didn't get scores, what to do here?
	// 	}
	// }

	// private static function updateSocialCache(outcome:Outcome<CallError>) {
	// 	switch(outcome) {
	// 		case SUCCESS:
	// 			FlxG.log.notice('social scores successfully retrieved');
	// 			updateCachedScores(true);
	// 			rushScoreSignal.dispatch();
	// 		case FAIL(error):
	// 			FlxG.log.warn('scores failed to be retrieved: ${error}');
	// 			// TODO: didn't get scores, what to do here?
	// 	}
	// }

	// private static function updateCachedScores(social:Bool) {
	// 	if (NG.core == null || !NG.core.loggedIn) {
	// 		// TODO: What to do for folks not signed in to NG?
	// 		return;
	// 	}

	// 	var board = NG.core.scoreBoards[SCOREBOARD_CHALLENGE_RUSH];

	// 	var scores = new Array<RushScore>();
	// 	for (score in board.scores) {
	// 		#if ngdebug
	// 		trace('who: ${score.user} -- raw:${score.value} -- nice:${score.formattedValue}');
	// 		#end

	// 		var item = new RushScore(score);
	// 		if (NG.core.user.id == score.user.id) {
	// 			item.isCurrentPlayer = true;
	// 		}

	// 		scores.push(item);
	// 	};

	// 	if (social) {
	// 		rushSocialTimes = scores;
	// 	} else {
	// 		rushGlobalTimes = scores;
	// 	}
	// }

	// public static function getRushScores(social:Bool):Array<RushScore> {
	// 	if (social) {
	// 		return rushSocialTimes;
	// 	} else {
	// 		return rushGlobalTimes;
	// 	}
	// }
}

// class RushScore {
// 	public var time:Float;
// 	public var isCurrentPlayer:Bool;
// 	public var userName:String;

// 	public function new(score:Score) {
// 		time = score.value / 1000.0;
// 		if (score.user.id != -1 && NG.core.user.id == score.user.id) {
// 			isCurrentPlayer = true;
// 		}
// 		userName = score.user.name.toUpperCase();
// 	}
// }