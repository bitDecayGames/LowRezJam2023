package collision;

import flixel.util.FlxColor;

enum abstract Color(Int) from Int to Int {
	var WHITE = FlxColor.WHITE;
	var YELLOW = FlxColor.YELLOW;
	var BLUE = FlxColor.BLUE;

	public function interacts(other:Color) {
		if (this == WHITE || other == WHITE) {
			return true;
		}

		var match = true;

		if (red() != 0xFF || other.red() != 0xFF) {
			match = other.red() == red();
		}
		if (green() != 0xFF || other.green() != 0xFF) {
			match = other.green() == green();
		}
		if (blue() != 0xFF || other.blue() != 0xFF) {
			match = other.blue() == blue();
		}

		return !match;
	}

	public function red():Int {
		return this & FlxColor.RED >> 16 & 0xFF;
	}

	public function green():Int {
		return this & FlxColor.LIME >> 8 & 0xFF;
	} 
	
	public function blue():Int {
		return this & FlxColor.BLUE & 0xFF;
	}
}