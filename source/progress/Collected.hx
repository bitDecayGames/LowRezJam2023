package progress;

import flixel.FlxG;
import collision.Color;

typedef Data = {
	version: String,
	gameCompleted: Bool,
	unlocks: {
		blueUnlocked: Bool,
		yellowUnlocked: Bool,
		redUnlocked: Bool,
	},
	checkpoint: {
		lastLevelID: String,
		lastEntityID: String,
		deaths: Int,
		time: Float,
	}
}

class Collected {
	private static var initialized = false;

	public static function newData():Data {
		return {
			version: "1",
			gameCompleted: false,
			unlocks: {
				blueUnlocked: false,
				yellowUnlocked: false,
				redUnlocked: false,
			},
			checkpoint: {
				time: 0,
				deaths: 0,
				lastLevelID: null,
				lastEntityID: null,
			}
		};
	}

	public static function initialize() {
		if (!initialized) {
			FlxG.save.bind("save", "bitdecaygames/lowrezjam2023/");
			if (FlxG.save.data.game == null || FlxG.save.data.version != "1" #if clearsave || true#end) {
				FlxG.save.data.game = Collected.newData();
				FlxG.save.flush();
			}
			initialized = true;
		}
	}

	public static function unlockRed() {
		FlxG.save.data.game.unlocks.redUnlocked = true;
		FlxG.save.flush();
	}

	public static function unlockBlue() {
		FlxG.save.data.game.unlocks.blueUnlocked = true;
		FlxG.save.flush();
	}

	public static function unlockYellow() {
		FlxG.save.data.game.unlocks.yellowUnlocked = true;
		FlxG.save.flush();
	}

	#if debug
	public static function remove(c:Color) {
		if (c == RED) {
			FlxG.save.data.game.unlocks.redUnlocked = false;
			FlxG.save.flush();
		}
		if (c == YELLOW) {
			FlxG.save.data.game.unlocks.yellowUnlocked = false;
			FlxG.save.flush();
		}
		if (c == BLUE) {
			FlxG.save.data.game.unlocks.blueUnlocked = false;
			FlxG.save.flush();
		}
	}
	#end

	public static function gameComplete() {
		clearCheckpoint();
		clearUnlocks();
		FlxG.save.data.game.gameComplete = true;
		FlxG.save.flush();
	}

	public static function setLastCheckpoint(levelID:String, entityID:String) {
		FlxG.save.data.game.checkpoint.lastLevelID = levelID;
		FlxG.save.data.game.checkpoint.lastEntityID = entityID;
		FlxG.save.flush();
	}

	static function clearCheckpoint() {
		FlxG.save.data.game.checkpoint = {
			lastLevelID: null,
			lastEntityID: null,
			time: 0.0,
			deaths: 0,
		};
		FlxG.save.flush();
	}

	static function clearUnlocks() {
		FlxG.save.data.game.checkpoint = null;
		FlxG.save.flush();
	}

	public static function getCheckpointLevel() {
		return FlxG.save.data.game.checkpoint.lastLevelID;
	}

	public static function getCheckpointEntity() {
		return FlxG.save.data.game.checkpoint.lastEntityID;
	}

	public static function addDeath() {
		FlxG.save.data.game.checkpoint.deaths++;
		FlxG.save.flush();
	}

	public static function getDeathCount() {
		return FlxG.save.data.game.checkpoint.deaths;
	}

	public static function addTime(t:Float) {
		FlxG.save.data.game.checkpoint.time += t;
		FlxG.save.flush;
	}

	public static function getTime():Float {
		return FlxG.save.data.game.checkpoint.time;
	}

	public static function has(c:Color) {
		return switch (c) {
			case RED: FlxG.save.data.game.unlocks.redUnlocked;
			case YELLOW: FlxG.save.data.game.unlocks.yellowUnlocked;
			case BLUE: FlxG.save.data.game.unlocks.blueUnlocked;
			default: false;
		}
	}

	public static function unlockedColors():Array<Color> {
		var colors = [ EMPTY ];

		if (has(RED)) {
			colors.push(RED);
		}
		
		if (has(YELLOW)) {
			colors.push(YELLOW);
		}
		
		if (has(BLUE)) {
			colors.push(BLUE);
		}

		return colors;
	}

	public static function setMusicParameters() {
		if (has(Color.BLUE)) {
			FmodManager.SetEventParameterOnSong("Layer2", 1);
		}
		if (has(Color.YELLOW)) {
			FmodManager.SetEventParameterOnSong("Layer3", 1);
		}
		if (has(Color.RED)) {
			FmodManager.SetEventParameterOnSong("Layer4", 1);
		}
	}
}