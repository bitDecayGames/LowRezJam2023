package collision;

import flixel.util.FlxColor;

enum abstract Color(Int) from Int to Int {
	var EMPTY = FlxColor.WHITE & 0xFFFFFF;
	
	// Primary
	var BLUE = 0x8888FF;
	var YELLOW = 0xEEEE33;
	var RED = 0xFF5555;
	
	// Secondary
	var GREEN = 0x3CAC3C;
	var PURPLE = 0xAA00AA;
	var ORANGE = 0xD96A20;

	// Third order
	var ALL = 0x000000;

	public function interacts(other:Color) {
		if (this == EMPTY || other == EMPTY) {
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

	public function add(i:Color):Color {
		if (this == EMPTY) {
			return i;
		}

		// check primary
		if (this == RED) {
			if (i == RED) {
				return RED;
			}
			if (i == YELLOW) {
				return ORANGE;
			}
			if (i == BLUE) {
				return PURPLE;
			}
		}
		if (this == YELLOW) {
			if (i == RED) {
				return ORANGE;
			}
			if (i == YELLOW) {
				return YELLOW;
			}
			if (i == BLUE) {
				return GREEN;
			}
		}
		if (this == BLUE) {
			if (i == RED) {
				return PURPLE;
			}
			if (i == YELLOW) {
				return GREEN;
			}
			if (i == BLUE) {
				return BLUE;
			}
		}

		// check secondary
		if (this == GREEN) {
			if (i == RED) {
				return ALL;
			}
			if (i == YELLOW) {
				return GREEN;
			}
			if (i == BLUE) {
				return GREEN;
			}
		}
		if (this == PURPLE) {
			if (i == RED) {
				return PURPLE;
			}
			if (i == YELLOW) {
				return ALL;
			}
			if (i == BLUE) {
				return PURPLE;
			}
		}
		if (this == ORANGE) {
			if (i == RED) {
				return ORANGE;
			}
			if (i == YELLOW) {
				return ORANGE;
			}
			if (i == BLUE) {
				return ALL;
			}
		}

		return ALL;
	}

	public function sub(i:Color):Color {
		// Start with black
		if (this == ALL) {
			if (i == RED) {
				return GREEN;
			}
			if (i == YELLOW) {
				return PURPLE;
			}
			if (i == BLUE) {
				return ORANGE;
			}
		}

		// then check secondaries
		if (this == GREEN) {
			if (i == RED) {
				return GREEN;
			}
			if (i == YELLOW) {
				return BLUE;
			}
			if (i == BLUE) {
				return YELLOW;
			}
		}
		if (this == PURPLE) {
			if (i == RED) {
				return BLUE;
			}
			if (i == YELLOW) {
				return PURPLE;
			}
			if (i == BLUE) {
				return RED;
			}
		}
		if (this == ORANGE) {
			if (i == RED) {
				return YELLOW;
			}
			if (i == YELLOW) {
				return RED;
			}
			if (i == BLUE) {
				return ORANGE;
			}
		}

		// Only primary we can remove is our own color
		if (this == i) {
			return EMPTY;
		}

		return this;

	}

	public function red():Int {
		return (this & FlxColor.RED) >> 16 & 0xFF;
	}

	public function green():Int {
		return (this & FlxColor.LIME) >> 8 & 0xFF;
	} 
	
	public function blue():Int {
		return (this & FlxColor.BLUE) & 0xFF;
	}

	public function dump():String {
		return 'r: ${red()}, g: ${green()}, b: ${blue()}';
	}
}