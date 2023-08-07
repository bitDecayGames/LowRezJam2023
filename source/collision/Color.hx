package collision;

import flixel.util.FlxColor;

enum abstract Color(Int) from Int to Int {
	// Full white behaves oddly with certain things... so one off
	var EMPTY = FlxColor.WHITE & 0xFFFFFE;
	
	// Primary
	var BLUE = 0x8888FF;
	var YELLOW = 0xFFFF5E;
	var RED = 0xFF5555;
	
	// Secondary
	var GREEN = 0x3CAC3C;
	var PURPLE = 0xAA00AA;
	var ORANGE = 0xDF7A37;

	// Third order
	var ALL = 0x292929;

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

	public function toFlxColor():FlxColor {
		return this | 0xFF000000;
	}

	public function name():String {
		return switch (this) {
			case RED: "RED";
			case YELLOW: "YELLOW";
			case BLUE: "BLUE";
			case ORANGE: "ORANGE";
			case GREEN: "GREEN";
			case PURPLE: "PURPLE";
			case ALL: "ALL";
			default: "EMPTY";
		}
	}

	public function dump():String {
		return 'r: ${red()}, g: ${green()}, b: ${blue()}';
	}

	public static function fromStr(str:String):Color {
		return switch (str) {
				case "RED": RED;
				case "YELLOW": YELLOW;
				case "BLUE": BLUE;
				case "EMPTY": EMPTY;
				default: 
					QuickLog.error('unrecognized color enum value: $str');
					return ALL;
		}
	}

	public static function fromEnum(e:Enum_Color) {
		return fromStr(e.getName());
	}


	public static function asList() {
		// TODO: Expand to all colors
		return [RED, YELLOW, BLUE];
	}
}