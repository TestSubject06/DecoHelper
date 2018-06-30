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
import flixel.FlxObject;

//TODO
//Calibration of pixels -> distance		DONE
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
	public var offsetStart:FlxPoint = null;
	
	private var drawingBuffer:FlxSprite;
	private var objects:FlxTypedGroup<FlxSprite>;
	public var textfield:FlxUIInputText;
	
	private var calibrationDistance:Float = 0.0;
	private var pixelsPerInch:Float = 2.030;
	
	private var hitTester:FlxSprite;
	private var closestObject:FlxSprite;
	private var selectedObject:FlxSprite;
	
	private var tools:FlxTypedGroup<FlxSprite>;
	private var toolbarSelect:FlxSprite;
	private var toolbarMeasure:FlxSprite;
	private var toolbarPan:FlxSprite;
	private var toolbarRectangle:FlxSprite;
	private var toolbarCircle:FlxSprite;
	
	private var selectedTool:String = "Select";
	private var lastTool:String = "";
	
	override public function create():Void
	{
		super.create();
		
		FlxG.camera.antialiasing = true;
		
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
		
		hitTester = new FlxSprite(0, 0);
		hitTester.makeGraphic(4, 4, 0xFF000000);
		hitTester.offset.set(2, 2);
		add(hitTester);
		
		buildToolbar();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (FlxG.keys.justPressed.SPACE){
			lastTool = selectedTool;
			selectedTool = "Pan";
		}
		if (FlxG.keys.justReleased.SPACE){
			selectedTool = lastTool;
		}
		
		if (FlxG.mouse.justPressed){
			if (!FlxG.keys.pressed.SPACE){
				clickStart = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
				dragging = true;
			}else{
				clickStart = FlxPoint.get(FlxG.mouse.screenX, FlxG.mouse.screenY);
				offsetStart = FlxPoint.get(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
			}
		}
		
		if (FlxG.mouse.justReleased && dragging){
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
		}else if (FlxG.mouse.justReleased && !dragging){
			clickStart.put();
			offsetStart.put();
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
			FlxG.camera.scroll.x = offsetStart.x + (clickStart.x - FlxG.mouse.screenX);
			FlxG.camera.scroll.y = offsetStart.y + (clickStart.y - FlxG.mouse.screenY);
		}
		
		hitTester.x = FlxG.mouse.x;
		hitTester.y = FlxG.mouse.y;
		
		objects.forEach(function(object:FlxSprite){ object.color = 0xFFFFFFFF; });
		closestObject = null;
		FlxG.overlap(hitTester, objects, overlapTest);
		if (closestObject != null){
			closestObject.color = 0xFFFF0000;
		}
		
		tools.forEach(function(tool){tool.color = 0xFFFFFFFF; });
		getToolSprite(selectedTool).color = 0xFF00FF00;
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
	
	private function overlapTest(mouseTester:FlxObject, lineObject:FlxObject):Void{
		var _mouseTester:FlxSprite = cast(mouseTester, FlxSprite);
		var _lineObject:FlxSprite = cast(lineObject, FlxSprite);
		
		if (closestObject == null){
			closestObject = _lineObject;
			return;
		}
		
		if (FlxMath.distanceBetween(_mouseTester, _lineObject) < FlxMath.distanceBetween(_mouseTester, closestObject)){
			closestObject = _lineObject;
		}
	}
	
	private function buildToolbar(){
		FlxG.cameras.add(new flixel.FlxCamera(0, 0, 60, 260, 1));
		flixel.FlxCamera.defaultCameras = [FlxG.camera];
		
		tools = new FlxTypedGroup();
		
		toolbarSelect = new FlxSprite(5, 5, AssetPaths.SelectMove__png);
		toolbarSelect.cameras = [FlxG.cameras.list[1]];
		tools.add(toolbarSelect);
		
		toolbarMeasure = new FlxSprite(5, 55, AssetPaths.Measure__png);
		toolbarMeasure.cameras = [FlxG.cameras.list[1]];
		tools.add(toolbarMeasure);
		
		toolbarPan = new FlxSprite(5, 105, AssetPaths.Pan__png);
		toolbarPan.cameras = [FlxG.cameras.list[1]];
		tools.add(toolbarPan);
		
		toolbarRectangle = new FlxSprite(5, 155, AssetPaths.Rectangle__png);
		toolbarRectangle.cameras = [FlxG.cameras.list[1]];
		tools.add(toolbarRectangle);
		
		toolbarCircle = new FlxSprite(5, 205, AssetPaths.Circle__png);
		toolbarCircle.cameras = [FlxG.cameras.list[1]];
		tools.add(toolbarCircle);
		
		add(tools);
	}
	
	function getToolSprite(tool:String):FlxSprite{
		switch(tool){
			case "Select":
				return toolbarSelect;
			
			case "Pan":
				return toolbarPan;
				
			case "Rectangle":
				return toolbarRectangle;
				
			case "Circle":
				return toolbarCircle;
				
			case "Measure":
				return toolbarMeasure;
		}
		return null;
	}
}