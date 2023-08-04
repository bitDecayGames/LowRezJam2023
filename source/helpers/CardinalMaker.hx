package helpers;

import bitdecay.flixel.spacial.Cardinal;

class CardinalMaker {
	public static function fromString(input:String) {
		if (input == "NORTH") {
			return Cardinal.N;
		} else if (input == "EAST") {
			return Cardinal.E;
		} else if (input == "SOUTH") {
			return Cardinal.S;
		} else if (input == "WEST") {
			return Cardinal.W;
		} else {
			return Cardinal.NONE;
		}
	}
}