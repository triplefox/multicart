package com.ludamix.multicart.d;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.Lib;

typedef KnobStyle = { bg:Int, fg:Int, line:Int };

class Knob extends Sprite
{
	
	public var tuner : Tuner;
	public var vg /* grabbed==true? */ : Bool; public var gy /* grab y */ : Float;
	public var va /* value acceleration */ : Float; public var vv /* velocity */ : Float; public var vf /* friction */ : Float; public var vd /* deadzone */: Float;
	public var gs /* grab scaling */ : Float;
	public var radius : Float;
	public var dirty : Bool;
	public var color : KnobStyle;
	
	private static var _pts : Array<{x:Float,y:Float}>;	
	
	private static inline var ARNG = 64;
	
	public static function init()
	{
		var tau = Math.PI * 2; var _amul = tau / (ARNG-1);
		_pts = [for (i in 0...ARNG) { x: -Math.sin(i * _amul), y: Math.cos(i * _amul) } ];		
	}
	
	public function new(circumference: Float, tuner : Tuner, ?vf = 0.7, ?vd = 0.0005, ?gs = 0.006, 
		?color : KnobStyle = null) { dirty = true; if (color == null) color = { bg:0xFF222222, fg:0xFFAAAAAA, line:0xFFCCCCCC }; this.color = color;
		super(); this.radius = circumference / 2; this.vf = vf; this.vd = vd; va = 0.; vv = 0.; vg = false;
		this.gs = gs;
		this.tuner = tuner;
		for (n in [MouseEvent.MOUSE_MOVE, MouseEvent.CLICK, MouseEvent.RIGHT_CLICK, MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_UP, MouseEvent.RELEASE_OUTSIDE])
			this.addEventListener(n, function(ev) { if (!vg) onMouse(ev); } ); /* allow top level to pass in events when grabbing */
		if (_pts == null) init();
		render();
	}
	
	public function uninit()
	{
		for (n in [MouseEvent.MOUSE_MOVE, MouseEvent.CLICK, MouseEvent.RIGHT_CLICK, MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_UP,MouseEvent.RELEASE_OUTSIDE])
			this.removeEventListener(n, onMouse);		
	}
	
	public function render()
	{
		if (!dirty && !vg) return; dirty = false;
		if (vg)  /* update grab, accelerate the knob */
		{
			var lx = Lib.current.stage.mouseX; var ly = Lib.current.stage.mouseY;
			va = gy - ly; gy = ly;
			/* accelerate */
			vv += va * gs; va = 0.; vv *= vf; if (Math.abs(vv) < vd) vv = 0.;
			tuner.si(tuner.i + vv);
		}
		else { tuner.refresh(); }
		var g = this.graphics; g.clear(); var bg = color.bg; var fg = color.fg; g.lineStyle(0, color.line);
		
		{ /* draw the knob */
			var r = radius; var x = r; var y = x;
			/* circle */ g.beginFill(bg); g.drawCircle(x, y, r); g.endFill(); g.moveTo(x, y + r * 0.5); g.lineTo(x, y + r);
			/* arc */ var pct = tuner.pcti(); g.beginFill(fg); g.moveTo(x, y);
				var sl = Math.round(T.clamp(0.,ARNG, T.lscale(0, 1, 0, ARNG, pct)));
				for (n in 0...sl) { g.lineTo((_pts[n].x * r) + x, (_pts[n].y * r) + y); }
				g.lineTo(x, y); g.endFill();
		}
		
	}
	
	public function onMouse(ev : MouseEvent)
	{
		if (ev.type == MouseEvent.MOUSE_DOWN) { vg = true; vv = 0.; va = 0.; gy = Lib.current.stage.mouseY; }
		else if (ev.type == MouseEvent.MOUSE_UP) { vg = false; }
		if (ev.type == MouseEvent.RIGHT_CLICK) { tuner.so(tuner.d); dirty = true; }
	}
	
}
