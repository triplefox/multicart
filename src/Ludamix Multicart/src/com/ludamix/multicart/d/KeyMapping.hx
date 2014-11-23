package com.ludamix.multicart.d;

enum KeyType
{
	KeyFloatIncrement;
	KeyFloatSet;
	KeyIntIncrement;
	KeyIntSet;
	KeyBool;
	KeyLambda; /* Tuner->KeyMapping->TunerType<T> */
	KeyNull;
}

class KeyMapping
{
	
	public var c /*code*/ : Int;
	public var td /*down type*/ : KeyType;
	public var th /*hold type*/ : KeyType;
	public var tu /*up type*/ : KeyType;
	public var id /*down data*/ : Dynamic;
	public var ih /*hold data*/ : Dynamic;
	public var iu /*up data*/ : Dynamic;
	public var imd /*input mapping down*/ : String;
	public var imh /*input mapping hold*/ : String;
	public var imu /*input mapping up*/ : String;
	public var held : Bool;

	public function new() { held = false; }
	
	private function doKey(t : Tuner, type : KeyType, data : Dynamic)
	{
		switch(type)
		{
			case KeyFloatIncrement: t.si(t.i + data);
			case KeyFloatSet: t.si(data);
			case KeyIntIncrement: t.si(t.i + data);
			case KeyIntSet: t.si(data);
			case KeyBool: t.si(data);
			case KeyLambda: t.si(data(t, this));
			case KeyNull:
		}
	}
	
	public function down(t : Tuner) { if (!held) { doKey(t, td, id); } held = true; }
	public function hold(t : Tuner) { doKey(t, th, ih); }
	public function up(t : Tuner) { if (held) doKey(t, tu, iu); held = false; }
	
	/* conveniences */
	public static function btap(c : Int, m : String) 
	{ var k = new KeyMapping(); k.c = c; 
		k.td = KeyBool; k.th = KeyNull; k.tu = KeyBool; 
		k.id = true; k.ih = null; k.iu = false; 
		k.imd = m; k.imh = m; k.imu = m; return k; }
	public static function bhold(c : Int, m : String) 
	{ var k = new KeyMapping(); k.c = c; 
		k.td = KeyBool; k.th = KeyBool; k.tu = KeyBool; 
		k.id = true; k.ih = true; k.iu = false; 
		k.imd = m; k.imh = m; k.imu = m; return k; }
	public static function intset(c : Int, m : String, v : Int) 
	{ var k = new KeyMapping(); k.c = c; 
		k.td = KeyNull; k.th = KeyIntSet; k.tu = KeyNull; 
		k.id = null; k.ih = v; k.iu = null; 
		k.imd = m; k.imh = m; k.imu = m; return k; }
	public static function intinc(c : Int, m : String, v : Int) 
	{ var k = new KeyMapping(); k.c = c; 
		k.td = KeyNull; k.th = KeyIntIncrement; k.tu = KeyNull; 
		k.id = null; k.ih = v; k.iu = null; 
		k.imd = m; k.imh = m; k.imu = m; return k; }
	public static function floatset(c : Int, m : String, v : Float) 
	{ var k = new KeyMapping(); k.c = c; 
		k.td = KeyNull; k.th = KeyFloatSet; k.tu = KeyNull; 
		k.id = null; k.ih = v; k.iu = null; 
		k.imd = m; k.imh = m; k.imu = m; return k; }
	public static function floatinc(c : Int, m : String, v : Float) 
	{ var k = new KeyMapping(); k.c = c; 
		k.td = KeyNull; k.th = KeyFloatIncrement; k.tu = KeyNull; 
		k.id = null; k.ih = v; k.iu = null; 
		k.imd = m; k.imh = m; k.imu = m; return k; }
	
}