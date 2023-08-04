package animation;

class AnimationState {
	var state = 0;

	public function new() {

	}

	public function add(s:Flag) {
		state = state | s;
	}

	public function remove(s:Flag) {
		state = state ^ s;
	}
	
	public function has(s:Flag) {
		return s & state != 0;
	}
	
	public function hasAll(s:Array<Flag>) {
		var mask = 0;
		for (i in s) {
			mask = mask | i;
		}
		return has(mask);
	}
	
		public function reset() {
			state = 0;
		}
}