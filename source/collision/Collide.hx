package collision;

import collision.Color.Color;
import echo.data.Data.CollisionData;
import echo.Body;

class Collide {
	static var ignoredCollisions = new Map<Body, Map<Color, Int>>();

	public static function ignoreCollisionsOfBColor(a:Body, b:Body) {
		modifyColorCollision(a, b, 1);

	}

	public static function restoreCollisions(a:Body, b:Body) {
		modifyColorCollision(a, b, -1);
	}

	static function modifyColorCollision(a:Body, b:Body, mod:Int) {
		if (b.object is ColorCollideSprite) {
			var bObj:ColorCollideSprite = cast b.object;
			var color = bObj.interactColor;

			if (!ignoredCollisions.exists(a)) {
				ignoredCollisions.set(a, new Map<Color, Int>());
			}

			var colorMap = ignoredCollisions.get(a);

			if (!colorMap.exists(color)) {
				colorMap.set(color, 0);
			}

			colorMap.set(color, colorMap.get(color) + mod);
		}
	}

	public static function collisionValid(a:Body, b:Body) {
		if (!(b.object is ColorCollideSprite)) {
			return true;
		}

		var bObj:ColorCollideSprite = cast b.object;
		var color = bObj.interactColor;

		if (!ignoredCollisions.exists(a)) {
			return true;
		}

		if (!ignoredCollisions.get(a).exists(color)) {
			return true;
		}

		return ignoredCollisions.get(a).get(color) == 0;
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