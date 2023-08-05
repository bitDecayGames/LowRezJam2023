package progress;

import flixel.FlxG;

typedef Data = {
	blueUnlocked: Bool,
	yellowUnlocked: Bool,
	redUnlocked: Bool,
	lastLevelID: String,
	lastEntityID: String
}

class Collected {
	private static var initialized = false;

	public static function newData():Data {
		return {
			blueUnlocked: false,
			yellowUnlocked: false,
			redUnlocked: false,
			lastLevelID: null,
			lastEntityID: null
		};
	}

	public static function initialize() {
		if (!initialized) {
			FlxG.save.bind("save", "bitdecaygames/lowrezjam2023/");
			if (FlxG.save.data.game == null #if clearsave || true#end) {
				FlxG.save.data.game = Collected.newData();
				FlxG.save.flush();
			}
			initialized = true;
		}
	}

	public static function unlockRed() {
		FlxG.save.data.game.redUnlocked = true;
		FlxG.save.flush();
	}

	public static function unlockBlue() {
		FlxG.save.data.game.blueUnlocked = true;
		FlxG.save.flush();
	}

	public static function unlockYellow() {
		FlxG.save.data.game.yellowUnlocked = true;
		FlxG.save.flush();
	}

	public static function setLastCheckpoint(levelID:String, entityID:String) {
		FlxG.save.data.game.lastLevelID = levelID;
		FlxG.save.data.game.lastEntityID = entityID;
		FlxG.save.flush();
	}

	public static function getCheckpointLevel() {
		return FlxG.save.data.game.lastLevelID;
	}

	public static function getCheckpointEntity() {
		return FlxG.save.data.game.lastEntityID;
	}
}