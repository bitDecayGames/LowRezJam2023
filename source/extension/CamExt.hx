package extension;

import flixel.math.FlxRect;
import flixel.FlxCamera;
import flixel.math.FlxPoint;

using bitdecay.flixel.extensions.FlxCameraExt;

class CamExt {
	static var tmp = FlxPoint.get();
	static var tmpRect = FlxRect.get();

	// returns distance away from the camera bounds. Returns 0 if point is in camera view
	public static function distanceFromBounds(cam:FlxCamera, p:FlxPoint):Float {
		
		if(cam.containsPoint(cam.project(p, tmp))) {
			return 0;
		}

		cam.getViewRect(tmpRect);
		tmpRect.x += cam.scroll.x;
		tmpRect.y += cam.scroll.y;

		pointOnRect(p.x, p.y, tmpRect.left, tmpRect.top, tmpRect.right, tmpRect.bottom, tmp);

		return tmp.distanceTo(p);
	}

	/**
	* Finds the intersection point between
	*     * the rectangle
	*       with parallel sides to the x and y axes 
	*     * the half-line pointing towards (x,y)
	*       originating from the middle of the rectangle
	*
	* Note: the function works given min[XY] <= max[XY],
	*       even though minY may not be the "top" of the rectangle
	*       because the coordinate system is flipped.
	* Note: if the input is inside the rectangle,
	*       the line segment wouldn't have an intersection with the rectangle,
	*       but the projected half-line does.
	* Warning: passing in the middle of the rectangle will return the midpoint itself
	*          there are infinitely many half-lines projected in all directions,
	*          so let's just shortcut to midpoint (GIGO).
	*
	* @param x:Number x coordinate of point to build the half-line from
	* @param y:Number y coordinate of point to build the half-line from
	* @param minX:Number the "left" side of the rectangle
	* @param minY:Number the "top" side of the rectangle
	* @param maxX:Number the "right" side of the rectangle
	* @param maxY:Number the "bottom" side of the rectangle
	* @param validate:boolean (optional) whether to treat point inside the rect as error
	* @return an object with x and y members for the intersection
	* @throws if validate == true and (x,y) is inside the rectangle
	* @author TWiStErRob
	* @licence Dual CC0/WTFPL/Unlicence, whatever floats your boat
	* @see <a href="http://stackoverflow.com/a/31254199/253468">source</a>
	* @see <a href="http://stackoverflow.com/a/18292964/253468">based on</a>
	*/
	static function pointOnRect(x:Float, y:Float, minX:Float, minY:Float, maxX:Float, maxY:Float, ?p:FlxPoint):FlxPoint {
		if (p == null) {
			p = FlxPoint.get();
		}
		var midX = (minX + maxX) / 2;
		var midY = (minY + maxY) / 2;
		// if (midX - x == 0) -> m == ±Inf -> minYx/maxYx == x (because value / ±Inf = ±0)
		var m = (midY - y) / (midX - x);

		if (x <= midX) { // check "left" side
			var minXy = m * (minX - x) + y;
			if (minY <= minXy && minXy <= maxY)
				p.set(minX, minXy);
				return p;
		}

		if (x >= midX) { // check "right" side
			var maxXy = m * (maxX - x) + y;
			if (minY <= maxXy && maxXy <= maxY) {
				p.set(maxX, maxXy);
				return p;
			}
		}

		if (y <= midY) { // check "top" side
			var minYx = (minY - y) / m + x;
			if (minX <= minYx && minYx <= maxX) {
				p.set(minYx, minY);
				return p;
			}
		}

		if (y >= midY) { // check "bottom" side
			var maxYx = (maxY - y) / m + x;
			if (minX <= maxYx && maxYx <= maxX) {
				p.set(maxYx, maxY);
				return p;
			}
		}

		// edge case when finding midpoint intersection: m = 0/0 = NaN
		if (x == midX && y == midY) {
			p.set(x, y);
			return p;
		}

		return p;
	}

	public static function lineIntersectsRectangle(cam:FlxCamera, a:FlxPoint, b:FlxPoint):Bool {
		cam.getViewRect(tmpRect);
		tmpRect.x += cam.scroll.x;
		tmpRect.y += cam.scroll.y;
		return lineRect(a.x, a.y, b.x, b.y, tmpRect.x, tmpRect.y, tmpRect.width, tmpRect.height);
	}

	// LINE/RECTANGLE
	static function lineRect(x1:Float, y1:Float, x2:Float, y2:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool {
		// check if the line has hit any of the rectangle's sides
		// uses the Line/Line function below
		var left =   lineLine(x1,y1,x2,y2, rx,ry,rx, ry+rh);
		var right =  lineLine(x1,y1,x2,y2, rx+rw,ry, rx+rw,ry+rh);
		var top =    lineLine(x1,y1,x2,y2, rx,ry, rx+rw,ry);
		var bottom = lineLine(x1,y1,x2,y2, rx,ry+rh, rx+rw,ry+rh);
	
		// if ANY of the above are true, the line
		// has hit the rectangle
		if (left || right || top || bottom) {
			return true;
		}
		return false;
	}

	// LINE/LINE
	static function lineLine(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float):Bool {
		// calculate the direction of the lines
		var uA:Float = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
		var uB:Float = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
	
		// if uA and uB are between 0-1, lines are colliding
		if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {
		return true;
		}
		return false;
	}
}