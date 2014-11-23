package com.ludamix.multicart.d;
import openfl.events.KeyboardEvent;

class InputConfig
{
	
	/* maps various devices (keyboard, mouse, etc.) to "tuners" - program state that is boxed and remapped to behave as a tunable range. */
	
	/* tuners */
	public var f : Map<String, Tuner>; public var i : Map<String, Tuner>; public var b : Map<String, Tuner>;
	/* key devices */
	public var kf : Map<Int, KeyMapping>; public var ki : Map<Int, KeyMapping>; public var kb : Map<Int, KeyMapping>;
	
	public function new()
	{
		resetTuners();
		resetDevices();
	}
	
	public function onKeyDown(key : KeyboardEvent)
	{
		if (kf.exists(key.keyCode)) { var m = kf.get(key.keyCode); if (f.exists(m.imd)) m.down(f.get(m.imd)); }
		if (ki.exists(key.keyCode)) { var m = kf.get(key.keyCode); if (i.exists(m.imd)) m.down(i.get(m.imd)); }
		if (kb.exists(key.keyCode)) { var m = kf.get(key.keyCode); if (b.exists(m.imd)) m.down(b.get(m.imd)); }
	}
	
	public function onKeyUp(key : KeyboardEvent)
	{
		if (kf.exists(key.keyCode)) { var m = kf.get(key.keyCode); if (f.exists(m.imu)) m.up(f.get(m.imu)); }
		if (ki.exists(key.keyCode)) { var m = kf.get(key.keyCode); if (i.exists(m.imu)) m.up(i.get(m.imu)); }
		if (kb.exists(key.keyCode)) { var m = kf.get(key.keyCode); if (b.exists(m.imu)) m.up(b.get(m.imu)); }
	}
	
	public function poll() /* update the tuners with polled state, e.g. held keys */
	{
		for (m in kf) { if (m.held && f.exists(m.imh)) m.hold(f.get(m.imh)); }
		for (m in ki) { if (m.held && i.exists(m.imh)) m.hold(i.get(m.imh)); }
		for (m in kb) { if (m.held && b.exists(m.imh)) m.hold(b.get(m.imh)); }
	}
	
	public function refresh(m : String) /* Synchronize a tuner's value against that of the program(e.g. for values that automatically change over time) */
	{
		if (f.exists(m)) f.get(m).refresh(); 
		if (i.exists(m)) i.get(m).refresh(); 
		if (b.exists(m)) b.get(m).refresh();
	}
	
	public function resetTuners() { f = new Map(); i = new Map(); b = new Map(); }
	
	public function resetDevices() { kf = new Map(); ki = new Map(); kb = new Map(); }
	
	/* conveniences */
	/* tuner declarations */
	public function tint(o : Dynamic, f : String, rg : RangeMapping, d : Int, m : String, n : String) { i.set(m, Tuner.makeInt(o,f,rg,d,m,n)); }
	public function tfloat(o : Dynamic, f : String, rg : RangeMapping, d : Float, m : String, n : String) { this.f.set(m, Tuner.makeFloat(o,f,rg,d,m,n)); }
	public function tbool(o : Dynamic, f : String, d : Bool, m : String, n : String) { b.set(m, Tuner.makeBool(o,f,d,m,n)); }
	/* key declarations */
	public function kbutton(c /*code*/ : Int, m /*mapping*/ : String) { kb.set(c, KeyMapping.bool(c, m)); }
	public function ksetv(c /*code*/ : Int, m /*mapping*/ : String, v : Float) { kf.set(c, KeyMapping.floatset(c, m, v)); ki.set(c, KeyMapping.intset(c, m, Math.round(v))); }
	public function kincv(c /*code*/ : Int, m /*mapping*/ : String, v : Float) { kf.set(c, KeyMapping.floatinc(c, m, v)); ki.set(c, KeyMapping.intinc(c, m, Math.round(v))); }
	
}