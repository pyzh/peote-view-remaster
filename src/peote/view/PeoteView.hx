package peote.view;

import peote.view.utils.Background;
import peote.view.utils.GLTool;
import peote.view.utils.RenderList;
import peote.view.utils.RenderListItem;

import peote.view.PeoteGL.GLTexture;
import peote.view.PeoteGL.GLFramebuffer;

@:allow(peote.view)
class PeoteView 
{
	public var gl(default, null):PeoteGL;
	
	var width:Int;
	var height:Int;
	
	#if (peoteview_es3 && peoteview_uniformbuffers)
	public var zoom(default, set):Float = 1.0;
	public inline function set_zoom(z:Float):Float {
		uniformBuffer.updateZoom(gl, z);
		return zoom = z;
	}
	public var xOffset(default, set):Int = 0;
	public inline function set_xOffset(offset:Int):Int {
		uniformBuffer.updateXOffset(gl, offset);
		return xOffset = offset;
	}
	public var yOffset(default, set):Int = 0;
	public inline function set_yOffset(offset:Int):Int {
		uniformBuffer.updateYOffset(gl, offset);
		return yOffset = offset;
	}
	#else
	public var zoom:Float = 1.0;
	public var xOffset:Int = 0;
	public var yOffset:Int = 0;
	#end
	
		
	
	var displayList:RenderList<Display>;
	
	var background:Background;
	
	#if (peoteview_es3 && peoteview_uniformbuffers)
	var uniformBuffer:UniformBufferView;
	#end
	
	public function new(gl:PeoteGL, width:Int, height:Int)
	{
		this.gl = gl;
		trace ("gl.version:" + gl.VERSION);
		//trace("EXTENSIONS:\n"+gl.getSupportedExtensions());
		/*
		// only ES2:
		trace("precision range low precision", gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.LOW_FLOAT).precision);
		trace("precision range low min", gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.LOW_FLOAT).rangeMin);
		trace("precision range low max", gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.LOW_FLOAT).rangeMax);
		*/
		
		this.width = width;
		this.height = height;
		
		#if (peoteview_es3 && peoteview_uniformbuffers)
		uniformBuffer = new UniformBufferView();
		uniformBuffer.createGLBuffer(gl, width, height, xOffset, yOffset, zoom);
		#end
		
		background = new Background(gl);
		
		displayList = new RenderList<Display>(new Map<Display,RenderListItem<Display>>());
	}
	
	public function setNewGLContext(newGl:PeoteGL) 
	{
		trace("PeoteView setNewGLContext");
		gl = newGl;
		#if (peoteview_es3 && peoteview_uniformbuffers)
		uniformBuffer.createGLBuffer(gl, width, height, xOffset, yOffset, zoom);
		#end
		// for all displays in list
		var listItem:RenderListItem<Display> = displayList.first;
		while (listItem != null)
		{
			listItem.value.setNewGLContext(gl);
			listItem = listItem.next;
		}
	}

	public function clearOldGLContext() 
	{
		trace("Display clearOldGLContext");
		#if (peoteview_es3 && peoteview_uniformbuffers)
		uniformBuffer.deleteGLBuffer(gl);
		#end
		// for all programms in list
		var listItem:RenderListItem<Display> = displayList.first;
		while (listItem != null)
		{
			listItem.value.clearOldGLContext();
			listItem = listItem.next;
		}
	}

 	public inline function hasDisplay(display:Display):Bool
	{
		return display.isIn(this);
	}
			
    /**
        Adds an Display instance to the RenderList. If it's already added it can be used to 
		change the order of rendering relative to another display in the List.

        @param  display Display instance to add into the RenderList or to change it's order
        @param  atDisplay (optional) to add or move the display before or after another display in the Renderlist (at default it adds at start or end)
        @param  addBefore (optional) set to `true` to add the display before another display or at start of the Renderlist (at default it adds after atDisplay or at end of the list)
    **/
	public function addDisplay(display:Display, ?atDisplay:Display, addBefore:Bool=false)
	{
		if (display.addToPeoteView(this)) displayList.add(display, atDisplay, addBefore);
		else throw ("Error: display is already added to this peoteView");
	}
	
    /**
        This function removes an Display instance from the RenderList.
    **/
	public function removeDisplay(display:Display):Void
	{
		displayList.remove(display);
		display.removedFromPeoteView();
	}

    /**
        This function need to call if window-size is changed
    **/
	public function resize(width:Int, height:Int):Void
	{
		this.width = width;
		this.height = height;
		// TODO: re-arange or resize all Displays
		
		#if (peoteview_es3 && peoteview_uniformbuffers)
		uniformBuffer.updateResolution(gl, width, height);
		#end
	}

	

	// ------------------------------------------------------------------------------
	// ----------------------------- Render -----------------------------------------
	// ------------------------------------------------------------------------------
	var framebuffer:GLFramebuffer = null;
	var fb_texture:GLTexture;
	public inline function getElementAt(mouseX:Int, mouseY:Int, display:Display, program:Program):Int
	{
		// TODO: another Function to call onClick eventhandler of all pickable 
		
		fb_texture = Texture.createEmptyTexture(gl, 1, 1);
		framebuffer = GLTool.createFramebuffer(gl);
		
		var picked = new lime.utils.UInt8Array(4); // TODO: for multitouch pick the whole view (width*height*4)
		
		// render to framebuffer
		gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fb_texture, 0);

		initGLViewport(1, 1);
		
		display.pick(mouseX, mouseY, this, program);
		
		// read picked pixel (element-number)
		if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE) {
			
			//GL.bindTexture (GL.TEXTURE_2D, fb_texture);
			gl.readPixels(0, 0, width, height, gl.RGBA, gl.UNSIGNED_BYTE, picked);
			//GL.bindTexture (GL.TEXTURE_2D, null);
		}
		else trace("PICKING ERROR: Framebuffer not complete");
		
		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		
		return(picked[3]<<24 | picked[2]<<16 | picked[1]<<8 | picked[0] - 1);
	}
	
	// ------------------------------------------------------------------------------
	private inline function initGLViewport(w:Int, h:Int):Void
	{
		gl.viewport (0, 0, w, h);
		
		gl.scissor(0, 0, w, h);
		gl.enable(gl.SCISSOR_TEST);	
		
		gl.clearColor(0.0, 0.0, 0.0, 1.0); // TODO: maybe alpha to 0.0 ?
		//gl.clearDepthf(0.0);
		
		gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT); //gl.STENCIL_BUFFER_BIT);
	}
	
	// ------------------------------------------------------------------------------
	var renderListItem:RenderListItem<Display>;
	var renderDisplay:Display;
	
	public function render():Void
	{	
		//trace("===peoteView.render===");

		initGLViewport(width, height);
		
		renderListItem = displayList.first;
		while (renderListItem != null)
		{

			renderDisplay = renderListItem.value;
			renderDisplay.render(this);
			
			renderListItem = renderListItem.next;
		}
		
	}
	

}