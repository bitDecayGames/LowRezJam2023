package collision;

import collision.Color.Color;
import echo.data.Data.CollisionData;
import echo.Body;

class Collide {
	static var ignoredCollisions = new Map<Body, Map<Body, Bool>>();

	public static function ignoreCollisions(a:Body, b:Body) {
		if (!ignoredCollisions.exists(a)) {
			ignoredCollisions.set(a, new Map<Body, Bool>());
		}

		ignoredCollisions.get(a).set(b, true);
	}

	public static function restoreCollisions(a:Body, b:Body) {
		if (!ignoredCollisions.exists(a)) {
			ignoredCollisions.set(a, new Map<Body, Bool>());
		}

		ignoredCollisions.get(a).remove(b);
	}

	public static function collisionValid(a:Body, b:Body) {
		return !ignoredCollisions.exists(a) || !ignoredCollisions.get(a).exists(b);
	}

	public static function colorBodiesDoNotInteract(a:Body, b:Body, data:Array<CollisionData>):Bool {
		return !colorBodiesInteract(a, b, data);
	}

	public static function colorBodiesInteract(a:Body, b:Body, data:Array<CollisionData>):Bool {
		if (!collisionValid(a, b)) {
			return false;
		}

		var aIsCType = Std.isOfType(a.object, ColorCollideSprite);
		var bIsCType = Std.isOfType(b.object, ColorCollideSprite);
		if (aIsCType && bIsCType) {
			var aColor:Color = cast cast(a.object, ColorCollideSprite).interactColor;
			var bColor:Color = cast cast(b.object, ColorCollideSprite).interactColor;
			return aColor.interacts(bColor);
		}
		return true;
	}

	public static function bodyInteractsWithColor(body:Body, color:Color) {
		if (Std.isOfType(body.object, ColorCollideSprite)) {
			var bodyColor:Color = cast cast(body.object, ColorCollideSprite).interactColor;
			return color.interacts(bodyColor);
		}

		return true;
	}
}