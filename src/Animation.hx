package;

import haxe.Timer;

import lime.ui.Window;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.MouseButton;

import peote.view.PeoteView;
import peote.view.Display;
import peote.view.Buffer;
import peote.view.Program;
//import peote.view.Texture;

import elements.ElementAnim;

class Animation 
{
	var peoteView:PeoteView;
	var element:ElementAnim;
	var buffer:Buffer<ElementAnim>;
	
	public function new(window:Window)
	{	
		peoteView = new PeoteView(window.context, window.width, window.height);
		
		buffer = new Buffer<ElementAnim>(100);

		var display   = new Display(10,10, window.width-20, window.height-20); display.green = 1.0;
		var program   = new Program(buffer);
		
		peoteView.addDisplay(display);  // display to peoteView
		display.addProgram(program);    // programm to display
	
		element  = new ElementAnim();
		buffer.addElement(element);     // element to buffer
		
		peoteView.start();
		
		element.setPosSize(20, 10, 50, 50);
		
		//element.x = 10;
		//element.xStart = 0;
		//element.xEnd = 110;
		
		//element.y = 10;
		//element.yStart =110;
		//element.yEnd = 10;
		element.animPosition(10, 400);
		
		//element.timePositionStart = 0;
		//element.timePositionDuration = 3;
		element.timePosition(0.0, 8.0);
		
		element.animColor(0xF2441100);
		
		buffer.updateElement(element);
				
		Timer.delay(function() {
			element.animSize(50,50,100,100);
			element.timeSize(3 , 1);
			//element.c = 0xFF000000;
			buffer.updateElement(element);
		}, 1000);
		Timer.delay(function() {
			//element.setPosSize(300, 100, 100, 100);	
			element.x = 300;
			buffer.updateElement(element);
		}, 5000);
		
	}
	
	// ---------------------------------------------------------------
	
	public function onMouseDown (x:Float, y:Float, button:MouseButton):Void
	{
	}

	public function onKeyDown (keyCode:KeyCode, modifier:KeyModifier):Void
	{
		switch (keyCode) {
			//case KeyCode.:
			default:
		}
	}

	public function render()
	{
		peoteView.render();
	}

	public function resize(width:Int, height:Int)
	{
		peoteView.resize(width, height);
	}

}