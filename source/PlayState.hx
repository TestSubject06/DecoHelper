package;

import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.ui.FlxUIInputText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxVector;
import flixel.util.FlxSpriteUtil;

//TODO
//Calibration of pixels -> distance
//Select and move drawn items
//Toolbar panel
//Panning the image with right click
//Rectangle furniture
//Circle furniture

//pixels per inch
//236 inches - 19 feet 8 inches
//477 pixels
//2.021 pixels per inch

class PlayState extends FlxState
{
	public var calibrating:Bool = true;
	
	public var dragging:Bool = false;
	public var clickStart:FlxPoint = null;
	
	private var drawingBuffer:FlxSprite;
	private var objects:FlxTypedGroup<FlxSprite>;
	public var textfield:FlxUIInputText;
	
	private var calibrationDistance:Float = 0.0;
	private var pixelsPerInch:Float = 2.043;
	
	override public function create():Void
	{
		super.create();
		
		add(new FlxSprite(0, 0, AssetPaths.floorplan__png));
		
		objects = new FlxTypedGroup();
		add(objects);
		
		drawingBuffer = new FlxSprite(0, 0);
		drawingBuffer.makeGraphic(FlxG.width, FlxG.height, 0x0);
		add(drawingBuffer);
		
		textfield = new FlxUIInputText();
		textfield.x = 50;
		textfield.y = 50;
		textfield.borderColor = 0xFFFFFFFF;
		textfield.text = "Some Text";
		textfield.size = 16;
		textfield.visible = false;
		add(textfield);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (FlxG.mouse.justPressed){
			clickStart = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
			if (!FlxG.keys.pressed.SHIFT){
				dragging = true;
			}
		}
		
		if (FlxG.mouse.justReleased){
			dragging = false;
			
			var pooledEndPoint = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
			
			var distance = Math.sqrt((pooledEndPoint.x - clickStart.x) * (pooledEndPoint.x - clickStart.x) + (pooledEndPoint.y - clickStart.y) * (pooledEndPoint.y - clickStart.y));
			FlxG.log.add("Pixels: " + distance);
			
			calibrationDistance = distance;
			
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
			
			//textfield.text = "";
			//textfield.visible = true;
			
			
			//Using the calibration, report the length of the line
			var totalInches:Float = distance / pixelsPerInch;
			var feet:Int = Math.floor(totalInches / 12);
			var inches:Float = FlxMath.roundDecimal(totalInches % 12, 1);
			FlxG.log.add("Distance: " + feet + "' " + inches + "\"");
			
			pooledEndPoint.put();
			clickStart.put();
		}
		
		if (FlxG.mouse.wheel > 0){
			FlxG.camera.zoom *= 1.05;
		}
		
		if (FlxG.mouse.wheel < 0){
			FlxG.camera.zoom *= .95;
		}
		
		if (FlxG.keys.justPressed.ENTER){
			FlxG.log.add(textfield.text);
		}
		
		if (FlxG.mouse.pressed && !dragging){
			//TODO: Math this.
			FlxG.camera.scroll.x = FlxG.mouse.x - clickStart.x;
			FlxG.camera.scroll.y = FlxG.mouse.y - clickStart.y;
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