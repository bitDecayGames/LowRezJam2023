package animation;

enum abstract Flag(Int) from Int to Int {
	var GROUNDED    = 0x1;
	var CROUCHED    = 0x1 << 1;
	var RUNNING     = 0x1 << 2;
	var ACCEL_LEFT  = 0x1 << 3;
	var ACCEL_RIGHT = 0x1 << 4;
}