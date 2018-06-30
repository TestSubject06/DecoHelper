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
//Select and move drawn items			DONE
//Toolbar panel							DONE
//Panning the image with right click	DONE
//Rectangle furniture					
//Circle furniture						
//Delete objects
//Show length/dimensions while drawing
//Brute force statistics
//

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
	private var activeTool:String = "";
	private var lastTool:String = "";
	private var ignoreClick:Bool = false;
	
	private var draggingSelectedObject:Bool = false;
	private var draggingObjectClickOffset:FlxPoint;
	
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
		
		if (!updateToolbar(elapsed) || ignoreClick){
			if (FlxG.mouse.justPressed){
				activeTool = selectedTool;
				handleClick(activeTool);
			}
			
			if (FlxG.mouse.justReleased){
				handleRelease(activeTool);	
			}
			
			if (FlxG.mouse.pressed){
				handleMouseHold(activeTool);
			}
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
		
		if ((FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.DELETE) && selectedObject != null && selectedTool == "Select" && !FlxG.mouse.pressed){
			objects.remove(selectedObject, true);
			selectedObject.destroy();
			selectedObject = null;
		}
		
		objects.forEach(function(object:FlxSprite){ object.color = 0xFFFFFFFF; });
		
		if (selectedTool == "Select"){
			hitTester.x = FlxG.mouse.x;
			hitTester.y = FlxG.mouse.y;
			
			closestObject = null;
			FlxG.overlap(hitTester, objects, overlapTest);
			if (closestObject != null){
				closestObject.color = 0xFFFF0000;
			}
		}
		
		if (selectedObject != null){
			selectedObject.color = 0xFF00FF00;
		}
		
		if (FlxG.mouse.justReleased && ignoreClick){
			ignoreClick = false;
		}
	}
	
	private function updateToolbar(elapsed:Float):Bool{
		var clickHandled = false;
		var uiPoint:FlxPoint = FlxG.mouse.getScreenPosition(FlxG.cameras.list[1]);
		
		if (FlxG.keys.justPressed.SPACE){
			lastTool = selectedTool;
			selectedTool = "Pan";
		}
		if (FlxG.keys.justReleased.SPACE){
			selectedTool = lastTool;
		}
		
		tools.forEach(function(tool:FlxSprite){
			tool.color = 0xFFFFFFFF;
			if (FlxG.cameras.list[1].containsPoint(uiPoint) && tool.overlapsPoint(uiPoint, true, FlxG.cameras.list[1])){
				tool.color = 0xFF00FFFF;
				if (FlxG.mouse.justPressed){
					setActiveTool(tool.ID);
				}
			}
		});
		
		if (FlxG.cameras.list[1].containsPoint(uiPoint) && 
			(FlxG.mouse.justPressed)){
			clickHandled = true;
			ignoreClick = true;
		}
		
		getToolSprite(selectedTool).color = 0xFF00FF00;
		uiPoint.put();
		
		return clickHandled;
	}
	
	function handleClick(activeTool){
		if (ignoreClick){
			return;
		}
		if (activeTool == "Pan"){
			clickStart = FlxPoint.get(FlxG.mouse.screenX, FlxG.mouse.screenY);
			offsetStart = FlxPoint.get(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
		}
		if (activeTool == "Measure" || activeTool == "Rectangle"){
			clickStart = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
			dragging = true;
		}
		if (activeTool == "Select"){
			selectedObject = closestObject;
			
			if (selectedObject != null){
				//start dragging it
				draggingSelectedObject = true;
				draggingObjectClickOffset = FlxPoint.get(selectedObject.x - FlxG.mouse.x, selectedObject.y - FlxG.mouse.y);
			}
		}
	}
	
	function handleRelease(activeTool){
		if (ignoreClick){
			return;
		}
		if (activeTool == "Measure"){
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
		
		if (activeTool == "Rectangle"){
			dragging = false;
			var pooledEndPoint = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
			
			var PSP:FlxPoint = FlxPoint.get(Math.min(clickStart.x, pooledEndPoint.x), Math.min(clickStart.y, pooledEndPoint.y));
			var PEP:FlxPoint = FlxPoint.get(Math.max(clickStart.x, pooledEndPoint.x), Math.max(clickStart.y, pooledEndPoint.y));
			
			var extents:FlxRect = FlxRect.get(
				Math.min(clickStart.x, pooledEndPoint.x)-2, 
				Math.min(clickStart.y, pooledEndPoint.y)-2,
				Math.abs(clickStart.x - pooledEndPoint.x)+4,
				Math.abs(clickStart.y - pooledEndPoint.y)+4
			);
			
			var newRect:FlxSprite = new FlxSprite(extents.x, extents.y);
			newRect.makeGraphic(Math.ceil(extents.width), Math.ceil(extents.height), 0x0, true);
			drawRectangle(newRect, PSP.subtract(extents.x, extents.y), PEP.subtract(extents.x, extents.y), 4);
			objects.add(newRect);
			
			pooledEndPoint.put();
			clickStart.put();
			PEP.put();
			PSP.put();
		}
		
		if (activeTool == "Pan"){
			clickStart.put();
			offsetStart.put();			
		}
		
		if (activeTool == "Select"){
			draggingSelectedObject = false;
			if (draggingObjectClickOffset != null){
				draggingObjectClickOffset.put();
				draggingObjectClickOffset = null;
			}
		}
	}
	
	function handleMouseHold(activeTool){
		if (ignoreClick){
			return;
		}
		if (activeTool == "Pan"){
			FlxG.camera.scroll.x = offsetStart.x + (clickStart.x - FlxG.mouse.screenX);
			FlxG.camera.scroll.y = offsetStart.y + (clickStart.y - FlxG.mouse.screenY);
		}
		
		if (activeTool == "Select"){
			if (selectedObject != null){
				selectedObject.x = FlxG.mouse.x + draggingObjectClickOffset.x;
				selectedObject.y = FlxG.mouse.y + draggingObjectClickOffset.y;				
			}
		}
	}
	
	override public function draw():Void 
	{
		drawingBuffer.pixels.fillRect(new Rectangle(0, 0, FlxG.width, FlxG.height), 0x0);
		if (dragging){
			var pooledEndPoint = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
			if (activeTool == "Measure"){
				drawBeam(drawingBuffer, clickStart, pooledEndPoint, 4);
			}
			if (activeTool == "Rectangle"){
				var bufferPoint:FlxPoint = FlxPoint.get(Math.min(clickStart.x, pooledEndPoint.x), Math.min(clickStart.y, pooledEndPoint.y));
				drawRectangle(drawingBuffer, bufferPoint, pooledEndPoint.set(Math.max(clickStart.x, pooledEndPoint.x), Math.max(clickStart.y, pooledEndPoint.y)), 4);
				bufferPoint.put();
			}
			pooledEndPoint.put();
		}
		super.draw();
	}
	
	function drawRectangle(target:FlxSprite, startPoint:FlxPoint, endPoint:FlxPoint, thickness:Int):Void{
		FlxSpriteUtil.drawRect(target, startPoint.x, startPoint.y, endPoint.x - startPoint.x, endPoint.y - startPoint.y, 0xFF000000, {thickness:thickness, color:0xFFFFFFFF});
		FlxSpriteUtil.drawRect(target, startPoint.x, startPoint.y, endPoint.x - startPoint.x, endPoint.y - startPoint.y, 0x0, {thickness:thickness / 2, color:0xFF000000});
		
		FlxSpriteUtil.drawLine(target, startPoint.x, startPoint.y, endPoint.x, endPoint.y, {thickness:thickness/2, color:0xFFFFFFFF});
		FlxSpriteUtil.drawLine(target, endPoint.x, startPoint.y, startPoint.x, endPoint.y, {thickness:thickness/2, color:0xFFFFFFFF});
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
		FlxG.cameras.add(new flixel.FlxCamera(0, 0, 55, 255, 1));
		flixel.FlxCamera.defaultCameras = [FlxG.camera];
		
		tools = new FlxTypedGroup();
		
		toolbarSelect = new FlxSprite(5, 5, AssetPaths.SelectMove__png);
		toolbarSelect.cameras = [FlxG.cameras.list[1]];
		toolbarSelect.ID = 1;
		tools.add(toolbarSelect);
		
		toolbarMeasure = new FlxSprite(5, 55, AssetPaths.Measure__png);
		toolbarMeasure.cameras = [FlxG.cameras.list[1]];
		toolbarMeasure.ID = 2;
		tools.add(toolbarMeasure);
		
		toolbarPan = new FlxSprite(5, 105, AssetPaths.Pan__png);
		toolbarPan.cameras = [FlxG.cameras.list[1]];
		toolbarPan.ID = 3;
		tools.add(toolbarPan);
		
		toolbarRectangle = new FlxSprite(5, 155, AssetPaths.Rectangle__png);
		toolbarRectangle.cameras = [FlxG.cameras.list[1]];
		toolbarRectangle.ID = 4;
		tools.add(toolbarRectangle);
		
		toolbarCircle = new FlxSprite(5, 205, AssetPaths.Circle__png);
		toolbarCircle.cameras = [FlxG.cameras.list[1]];
		toolbarCircle.ID = 5;
		tools.add(toolbarCircle);
		
		add(tools);
	}
	
	function setActiveTool(toolID:Int):Void{
		switch(toolID){
			case 1:
				selectedTool = "Select";
			
			case 2:
				selectedTool = "Measure";
				
			case 3:
				selectedTool = "Pan";
				
			case 4:
				selectedTool = "Rectangle";
				
			case 5:
				selectedTool = "Circle";
				
			default:
				selectedTool = "Select";
		}
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