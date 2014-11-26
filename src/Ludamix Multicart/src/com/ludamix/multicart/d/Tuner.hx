package com.ludamix.multicart.d;

enum TunerType
{
	TuneInt(rg : RangeMapping, limit /* constrain input to defined range */ : Bool);
	TuneFloat(rg : RangeMapping, limit /* constrain input to defined range */ : Bool);
	TuneBool;
}

typedef Box = { g : Void->Dynamic, s : Dynamic->Void };

class Tuner
{

	/* Note that RangeMapping inverts the idea of "input" and "output" used here, 
	because we generally want the _unit values_ to have a non-linear representation. */
	
	public var t /*type*/ : TunerType;
	public var i /*local input value*/ : Dynamic;
	public var o /*local output value*/ : Dynamic;
	public var b /*boxed output value*/ : Box;
	public var d /*default output value*/ : Dynamic;
	public var n /*display name*/ : String;
	public var m /*mapping name*/ : String;
	
	public function new() { }

	private function doLimit(v : Dynamic, l : Dynamic, h : Dynamic) { if (v < l) return l; else if (v > h) return h; return v; }
	
	public function refresh() : Bool
	{
		var cur = b.g(); 
		if (cur != o) { o = cur; 
			switch(t)
			{
				case TuneFloat(rg, limit): i = rg.o(o); if (limit) i = doLimit(i, rg.l2, rg.h2);
				case TuneInt(rg, limit): i = rg.o(o); if (limit) i = doLimit(i, rg.l2, rg.h2);
				case TuneBool: i = o;
			}
			return true; 
		} 
		else return false;
	}
	
	public function si(i : Dynamic) {
		switch(t)
		{
			case TuneFloat(rg, limit): if (limit) i = doLimit(i, rg.l2, rg.h2); o = rg.i(i);
			case TuneInt(rg, limit): if (limit) i = doLimit(i, rg.l2, rg.h2); o = Std.int(rg.i(i));
			case TuneBool: o = i;
		}
		this.i = i;
		b.s(o);
	}	
	
	public function so(o : Dynamic) { b.s(o); refresh(); }	
	
	public static function box(o : Dynamic, f : String) { return { 
		g:function() { return Reflect.field(o, f); },
		s:function(v : Dynamic) { Reflect.setField(o, f, v); }};
	}
	
	/* conveniences */
	public static function makeInt(o : Dynamic, f : String, rg : RangeMapping, d : Int, m : String, n : String, limit : Bool) {
		var t = new Tuner(); t.t = TuneInt(rg, limit); t.d = d; t.b = box(o, f); t.m = m; t.n = n; t.si(rg.o(t.b.g())); return t;
	}
	
	public static function makeFloat(o : Dynamic, f : String, rg : RangeMapping, d : Float, m : String, n : String, limit : Bool) {
		var t = new Tuner(); t.t = TuneFloat(rg, limit); t.d = d; t.b = box(o, f); t.m = m; t.n = n; t.si(rg.o(t.b.g())); return t;
	}
	
	public static function makeBool(o : Dynamic, f : String, d : Bool, m : String, n : String) {
		var t = new Tuner(); t.t = TuneBool; t.d = d; t.b = box(o, f); t.m = m; t.n = n; t.si(t.b.g()); return t;
	}
	
}