package peote.view;

import peote.view.utils.RenderList;
import peote.view.utils.RenderListItem;

@:allow(peote.view)
class Display 
{
	// params
	public var x:Int = 0; // x Position
	public var y:Int = 0; // y Position
	public var z:Int = 0; // z order
	public var width:Int = 0;  // width
	public var height:Int = 0; // height
	public var zoom:Float = 1.0;
	
	#if (peoteview_es3 && peoteview_uniformbuffers)
	public var xOffset(default, set):Int = 0;
	public function set_xOffset(offset:Int):Int {
		uniformBuffer.updateXOffset(gl, offset + x);
		return xOffset = offset;
	}
	public var yOffset(default, set):Int = 0;
	public function set_yOffset(offset:Int):Int {
		uniformBuffer.updateYOffset(gl, offset + y);
		return yOffset = offset;
	}
	#else
	public var xOffset:Int = 0;
	public var yOffset:Int = 0;
	#end
	
	// TODO: a 4 byte color uint
	public var red:Float = 0.0;
	public var green:Float = 0.0;
	public var blue:Float = 0.0;
	public var alpha:Float = 0.0;
	
	var peoteView:PeoteView = null;
	var gl:PeoteGL = null;

	var programList:RenderList<Program>;
		
	#if (peoteview_es3 && peoteview_uniformbuffers)
	var uniformBuffer:UniformBufferDisplay;
	#end

	public function new(x:Int, y:Int, width:Int, height:Int) 
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		
		programList = new RenderList<Program>(new Map<Program,RenderListItem<Program>>());
		#if (peoteview_es3 && peoteview_uniformbuffers)
		uniformBuffer = new UniformBufferDisplay();
		#end
	}

	private inline function addToPeoteView(peoteView:PeoteView):Bool
	{
		
		if (this.peoteView == peoteView) return false; // is already added
		else
		{
			if (this.peoteView != null) {  // was added to another peoteView
				this.peoteView.removeDisplay(this); // removing from the other one
			}
			
			this.peoteView = peoteView;
			
			if (this.gl != peoteView.gl) // new or different GL-Context
			{
				if (this.gl != null) clearOldGLContext(); // different GL-Context
				setNewGLContext(peoteView.gl);
			} // if it's stay into same gl-context, no buffers had to recreate/fill
			
			return true;
		}	

	}
	
	private inline function removedFromPeoteView():Void
	{
		peoteView = null;
	}
		
	
	private inline function setNewGLContext(newGl:PeoteGL) 
	{
		trace("Display setNewGLContext");
		gl = newGl;
		#if (peoteview_es3 && peoteview_uniformbuffers)
		uniformBuffer.createGLBuffer(gl, xOffset + x, yOffset + y);
		#end
		// for all programms in list
		var listItem:RenderListItem<Program> = programList.first;
		while (listItem != null)
		{
			listItem.value.setNewGLContext(gl);
			listItem = listItem.next;
		}
	}

	private inline function clearOldGLContext() 
	{
		trace("Display clearOldGLContext");
		#if (peoteview_es3 && peoteview_uniformbuffers)
		uniformBuffer.deleteGLBuffer(gl);
		#end
		// for all programms in list
		var listItem:RenderListItem<Program> = programList.first;
		while (listItem != null)
		{
			listItem.value.clearOldGLContext();
			listItem = listItem.next;
		}
	}

	
    /**
        Adds an Program instance to the RenderList. If it's already added it can be used to 
		change the order of rendering relative to another program in the List.

        @param  program Program instance to add into the RenderList or to change it's order
        @param  atProgram (optional) to add or move the program before or after another program in the Renderlist (at default it adds at start or end)
        @param  addBefore (optional) set to `true` to add the program before another program or at start of the Renderlist (at default it adds after atProgram or at end of the list)
    **/
	public function addProgram(program:Program, ?atProgram:Program, addBefore:Bool=false)
	{
		if (program.addToDisplay(this)) programList.add(program, atProgram, addBefore);
		else throw ("Error: program is already added to this display");
	}
	
    /**
        This function removes an Program instance from the RenderList.
    **/
	public function removeProgram(program:Program):Void
	{
		programList.remove(program);
		program.removedFromDisplay();
	}
	

	// ------------------------------------------------------------------------------
	// ----------------------------- Render -----------------------------------------
	// ------------------------------------------------------------------------------
	private inline function render_scissor(peoteView:PeoteView):Void
	{
		var sx:Int = Math.floor((x + peoteView.xOffset) * peoteView.zoom);
		var sy:Int = Math.floor((y + peoteView.yOffset) * peoteView.zoom);
		var sw:Int = Math.floor((width != 0) ? width * peoteView.zoom: peoteView.width * peoteView.zoom);
		var sh:Int = Math.floor((height != 0) ? height * peoteView.zoom: peoteView.height * peoteView.zoom);
		
		if (sx < 0) sw += sx;
		sx = Std.int( Math.max(0, Math.min(peoteView.width, sx)) );
		sw = Std.int( Math.max(0, Math.min(peoteView.width-sx, sw)) );
		
		if (sy < 0) sh += sy;
		sy = Std.int( Math.max(0, Math.min(peoteView.height, sy)) );
		sh = Std.int( Math.max(0, Math.min(peoteView.height-sy, sh)) );

		peoteView.gl.scissor(sx, peoteView.height - sh - sy, sw, sh);
	}
	
	var renderListItem:RenderListItem<Program>;
	var renderProgram:Program;
	
	private inline function render(peoteView:PeoteView):Void
	{
		
		//trace("  ---display.render---");
		
		render_scissor(peoteView);
		peoteView.background.render(red, green, blue, alpha);
		
		renderListItem = programList.first;
		while (renderListItem != null)
		{
			renderProgram = renderListItem.value;
			renderProgram.render(peoteView, this);
			
			renderListItem = renderListItem.next;// next program in renderlist
		}
		
	}
	
	// ------------------------------------------------------------------------------
	// ------------------------ OPENGL PICKING -------------------------------------- 
	// ------------------------------------------------------------------------------
	private function pick(peoteView:PeoteView, mouseX:Int, mouseY:Int):Void
	{
		// TODO: in buffer
		// how to enable Element-access ???
	}

}