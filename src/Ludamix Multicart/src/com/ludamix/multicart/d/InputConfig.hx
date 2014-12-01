package com.ludamix.multicart.d;
import openfl.events.KeyboardEvent;

class InputConfig
{
	
	/* maps various devices (keyboard, mouse, etc.) to "tuners" - program state that is boxed and remapped to behave as a tunable range. */
	
	/* tuners */
	public var f : Map<String, Array<Tuner>>; public var i : Map<String, Array<Tuner>>; public var b : Map<String, Array<Tuner>>;
	/* key devices */
	public var kf : Map<Int, Array<KeyMapping>>; public var ki : Map<Int, Array<KeyMapping>>; public var kb : Map<Int, Array<KeyMapping>>;
	
	public function new()
	{
		resetTuners();
		resetDevices();
	}
	
	/* return the keycodes currently held */
	public function keyState() { var r = new Array<Int>(); for (k in kf) { for (i in k) { if (i.held) r.push(i.c); }  } return r; }
	
	public function onKeyDown(key : KeyboardEvent)
	{
		if (kf.exists(key.keyCode)) { var a = kf.get(key.keyCode); for (m in a) { if (f.exists(m.imd)) { for (t in f.get(m.imd)) m.down(t); } } }
		if (ki.exists(key.keyCode)) { var a = ki.get(key.keyCode); for (m in a) { if (i.exists(m.imd)) { for (t in i.get(m.imd)) m.down(t); } } }
		if (kb.exists(key.keyCode)) { var a = kb.get(key.keyCode); for (m in a) { if (b.exists(m.imd)) { for (t in b.get(m.imd)) m.down(t); } } }
	}
	
	public function onKeyUp(key : KeyboardEvent)
	{
		if (kf.exists(key.keyCode)) { var a = kf.get(key.keyCode); for (m in a) { if (f.exists(m.imu)) { for (t in f.get(m.imu)) m.up(t); } } }
		if (ki.exists(key.keyCode)) { var a = ki.get(key.keyCode); for (m in a) { if (i.exists(m.imu)) { for (t in i.get(m.imu)) m.up(t); } } }
		if (kb.exists(key.keyCode)) { var a = kb.get(key.keyCode); for (m in a) { if (b.exists(m.imu)) { for (t in b.get(m.imu)) m.up(t); } } }
	}
	
	public function poll() /* update the tuners with polled state, e.g. held keys */
	{
		for (a in kf) { for (m in a) { if (m.held && f.exists(m.imh)) { for (t in f.get(m.imh)) m.hold(t); } } }
		for (a in ki) { for (m in a) { if (m.held && i.exists(m.imh)) { for (t in i.get(m.imh)) m.hold(t); } } }
		for (a in kb) { for (m in a) { if (m.held && b.exists(m.imh)) { for (t in b.get(m.imh)) m.hold(t); } } }
	}
	
	public function refresh(m : String) /* Synchronize a tuner's value against that of the program(e.g. for values that automatically change over time) */
	{
		if (f.exists(m)) { for (t in f.get(m)) t.refresh(); }
		if (i.exists(m)) { for (t in i.get(m)) t.refresh(); }
		if (b.exists(m)) { for (t in b.get(m)) t.refresh(); }
	}
	
	public function resetTuners() { f = new Map(); i = new Map(); b = new Map(); }
	
	public function resetDevices() { kf = new Map(); ki = new Map(); kb = new Map(); }
	
	/* conveniences */
	/* push to map<array<T>> */
	private function kpush(map : Map<Int, Array<KeyMapping>>, k, v) { if (!map.exists(k)) map.set(k, new Array<KeyMapping>()); map.get(k).push(v); }
	private function tpush(map : Map<String, Array<Tuner>>, k, v) { if (!map.exists(k)) map.set(k, new Array<Tuner>()); map.get(k).push(v); }
	/* tuner declarations - o:object, f:field, rg:output range, d:default output, m: mapping name, n: display name*/
	public function tint(o : Dynamic, f : String, rg : RangeMapping, d : Int, m : String, n : String, lim : Bool) { tpush(i, m, Tuner.makeInt(o,f,rg,d,m,n,lim)); }
	public function tfloat(o : Dynamic, f : String, rg : RangeMapping, d : Float, m : String, n : String, lim : Bool) { tpush(this.f, m, Tuner.makeFloat(o,f,rg,d,m,n,lim)); }
	public function tbool(o : Dynamic, f : String, d : Bool, m : String, n : String) { tpush(b, m, Tuner.makeBool(o,f,d,m,n)); }
	/* key declarations */
	/* When using a key, "<key>tap" and "<key>hold" are the button presses. 
	 * "<key>" usually substitutes for a continuous value change, e.g. a dial turn. 
	 * "tap" keys must have their value cleared manually by your program.
	 * */
	public function kbutton(c /*code*/ : Int, m /*mapping*/ : String) { ktap(c, m + "tap"); khold(c, m + "hold"); }
	public function ktap(c /*code*/ : Int, m /*mapping*/ : String) { kpush(kb, c, KeyMapping.btap(c, m)); }
	public function khold(c /*code*/ : Int, m /*mapping*/ : String) { kpush(kb, c, KeyMapping.bhold(c, m)); }
	public function ksetv(c /*code*/ : Int, m /*mapping*/ : String, v : Float) { kpush(kf, c, KeyMapping.floatset(c, m, v)); kpush(ki, c, KeyMapping.intset(c, m, Math.round(v))); }
	public function kincv(c /*code*/ : Int, m /*mapping*/ : String, v : Float) { kpush(kf, c, KeyMapping.floatinc(c, m, v)); kpush(ki, c, KeyMapping.intinc(c, m, Math.round(v))); }
	
}