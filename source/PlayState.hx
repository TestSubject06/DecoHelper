package;

import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxVector;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

//TODO
//Calibration of pixels -> distance
//Select and move drawn items
//Toolbar panel
//Panning the image with right click
//Rectangle furniture
//Circle furniture

class PlayState extends FlxState
{
	public var calibrating:Bool = true;
	
	public var dragging:Bool = false;
	public var clickStart:FlxPoint = null;
	
	private var drawingBuffer:FlxSprite;
	private var objects:FlxTypedGroup<FlxSprite>;
	
	override public function create():Void
	{
		super.create();
		
		add(new FlxSprite(0, 0, AssetPaths.floorplan__png));
		
		objects = new FlxTypedGroup();
		add(objects);
		
		drawingBuffer = new FlxSprite(0, 0);
		drawingBuffer.makeGraphic(FlxG.width, FlxG.height, 0x0);
		add(drawingBuffer);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (FlxG.mouse.justPressed){
			clickStart = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
			dragging = true;
		}
		
		if (FlxG.mouse.justReleased){
			dragging = false;
			
			var pooledEndPoint = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
			var extents:FlxRect = FlxRect.get(
				Math.min(clickStart.x, pooledEndPoint.x)-15, 
				Math.min(clickStart.y, pooledEndPoint.y)-15,
				Math.abs(clickStart.x - pooledEndPoint.x)+30,
				Math.abs(clickStart.y - pooledEndPoint.y)+30
			);
			
			var newBeam:FlxSprite = new FlxSprite(extents.x, extents.y);
			newBeam.makeGraphic(Math.ceil(extents.width), Math.ceil(extents.height), 0x0, true);
			drawBeam(newBeam, clickStart.subtract(extents.x, extents.y), pooledEndPoint.subtract(extents.x, extents.y), 4);
			objects.add(newBeam);
			
			pooledEndPoint.put();
			clickStart.put();
		}
		
		if (FlxG.mouse.wheel > 0){
			FlxG.camera.zoom *= 1.05;
		}
		
		if (FlxG.mouse.wheel < 0){
			FlxG.camera.zoom *= .95;
		}
	}
	
	override public function draw():Void 
	{
		drawingBuffer.pixels.fillRect(new Rectangle(0, 0, FlxG.width, FlxG.height), 0x0);
		if (dragging){
			var pooledEndPoint = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
			drawBeam(drawingBuffer, clickStart, pooledEndPoint, 4);
			pooledEndPoint.put();
		}
		super.draw();
	}
	
	function drawBeam(target:FlxSprite, startPoint:FlxPoint, endPoint:FlxPoint, thickness:Int){
		var leftNormal:FlxVector = endPoint.copyTo().subtractPoint(startPoint).toVector().normalize().leftNormal().scale(15);
		
		FlxSpriteUtil.drawLine(target, startPoint.x, startPoint.y, endPoint.x, endPoint.y, {thickness:thickness});
		FlxSpriteUtil.drawLine(target, startPoint.x, startPoint.y, startPoint.x + leftNormal.x, startPoint.y + leftNormal.y, {thickness:thickness});
		FlxSpriteUtil.drawLine(target, startPoint.x, startPoint.y, startPoint.x - leftNormal.x, startPoint.y - leftNormal.y, {thickness:thickness});
		
		FlxSpriteUtil.drawLine(target, endPoint.x, endPoint.y, endPoint.x + leftNormal.x, endPoint.y + leftNormal.y, {thickness:thickness});
		FlxSpriteUtil.drawLine(target, endPoint.x, endPoint.y, endPoint.x - leftNormal.x, endPoint.y - leftNormal.y, {thickness:thickness});
		
		FlxSpriteUtil.drawLine(target, startPoint.x, startPoint.y, endPoint.x, endPoint.y, {thickness:thickness/2, color:0xFF000000});
		FlxSpriteUtil.drawLine(target, startPoint.x, startPoint.y, startPoint.x + leftNormal.x, startPoint.y + leftNormal.y, {thickness:thickness/2, color:0xFF000000});
		FlxSpriteUtil.drawLine(target, startPoint.x, startPoint.y, startPoint.x - leftNormal.x, startPoint.y - leftNormal.y, {thickness:thickness/2, color:0xFF000000});
		
		FlxSpriteUtil.drawLine(target, endPoint.x, endPoint.y, endPoint.x + leftNormal.x, endPoint.y + leftNormal.y, {thickness:thickness/2, color:0xFF000000});
		FlxSpriteUtil.drawLine(target, endPoint.x, endPoint.y, endPoint.x - leftNormal.x, endPoint.y - leftNormal.y, {thickness:thickness/2, color:0xFF000000});
	}
}