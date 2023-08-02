package collision;

import collision.Color.Color;
import echo.data.Data.CollisionData;
import echo.Body;

class Collide {
	public static function colorsInteract(a:Body, b:Body, data:Array<CollisionData>):Bool {
		var aIsCType = Std.isOfType(a.object, ColorCollideSprite);
		var bIsCType = Std.isOfType(b.object, ColorCollideSprite);
		if (aIsCType && bIsCType) {
			var aColor:Color = cast cast(a.object, ColorCollideSprite).color;
			var bColor:Color = cast cast(b.object, ColorCollideSprite).color;
			return aColor.interacts(bColor);
		}
		return false;
	}
}