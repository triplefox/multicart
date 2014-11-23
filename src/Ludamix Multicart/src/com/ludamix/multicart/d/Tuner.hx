package com.ludamix.multicart.d;

enum TunerType
{
	TuneInt(rg : RangeMapping);
	TuneFloat(rg : RangeMapping);
	TuneBool;
}

typedef Box = { g : Void->Dynamic, s : Dynamic->Void };

class Tuner
{
	
	public var t /*type*/ : TunerType;
	public var i /*local input value*/ : Dynamic;
	public var o /*local output value*/ : Dynamic;
	public var b /*boxed output value*/ : Box;
	public var d /*default output value*/ : Dynamic;
	public var n /*display name*/ : String;
	public var m /*mapping name*/ : String;
	
	public function new() {}
	
	public function refresh() : Bool
	{
		var cur = b.g(); 
		if (cur != o) { o = cur; 
			switch(t)
			{
				case TuneFloat(rg): i = rg.i(o);
				case TuneInt(rg): i = rg.i(o);
				case TuneBool: i = o;
			}
			return true; 
		} 
		else return false;
	}
	
	public function si(i : Dynamic) {
		this.i = i;
		switch(t)
		{
			case TuneFloat(rg): o = rg.o(i); 
			case TuneInt(rg): o = Std.int(rg.o(i));
			case TuneBool: o = i;
		}
		b.s(o);
	}	
	
	public function so(o : Dynamic) { b.s(o); refresh(); }	
	
	public static function box(o : Dynamic, f : String) { return { 
		g:function() { return Reflect.field(o, f); },
		s:function(v : Dynamic) { Reflect.setField(o, f, v); }};
	}
	
	/* conveniences */
	public static function makeInt(o : Dynamic, f : String, rg : RangeMapping, d : Int, m : String, n : String) {
		var t = new Tuner(); t.t = TuneInt(rg); t.d = d; t.b = box(o, f); t.m = m; t.n = n; t.si(rg.i(t.b.g())); return t;
	}
	
	public static function makeFloat(o : Dynamic, f : String, rg : RangeMapping, d : Float, m : String, n : String) {
		var t = new Tuner(); t.t = TuneFloat(rg); t.d = d; t.b = box(o, f); t.m = m; t.n = n; t.si(rg.i(t.b.g())); return t;
	}
	
	public static function makeBool(o : Dynamic, f : String, d : Bool, m : String, n : String) {
		var t = new Tuner(); t.t = TuneBool; t.d = d; t.b = box(o, f); t.m = m; t.n = n; t.si(t.b.g()); return t;
	}
	
}