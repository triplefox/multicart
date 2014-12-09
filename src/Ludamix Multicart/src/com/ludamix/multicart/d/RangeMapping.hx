package com.ludamix.multicart.d;

class RangeMapping
{
	/* map range "1" (input) to range "2" (output) with curvature c as the exponent of the output range. */
	public var l1 /*low*/ : Float; public var h1 /*hi*/ : Float; public var c /*curvature*/ : Float; public var l2 /*low 2*/ : Float; public var h2 /*hi 2*/ : Float;
	public function new(l1, h1, l2, h2, c) { this.l1 = l1; this.h1 = h1; this.l2 = l2; this.h2 = h2; this.c = c; }
	public function o(v : Float) /* input -> output */ 
		{ var lv /*linear value*/ = sc(l1, h1, l2, h2, v); if (lv > 0) return Math.pow(lv, c); else return -Math.pow( -lv, c); }
	public function i(cv : Float) /* output -> input */ 
		{ var lv /*linear value*/ = 0.; if (cv > 0) lv = Math.pow(cv, 1 / c); else lv = -Math.pow( -cv, 1 / c); return sc(l2, h2, l1, h1, lv); }
	static inline function sc(a0 : Float, a1 : Float, b0 : Float, b1 : Float, i : Float) { var ar = a1 - a0; var br = b1 - b0; return (i - a0) * (br / ar) + b0; };	
	
	/* range 1 or range 2 remapped to a 0-1 spectrum */
	public function pct2(cv : Float) { return sc(l2, h2, 0., 1., cv); }
	public function pct1(v : Float) { return pct2(i(v)); }
	/* length of range 1 and 2 */
	public inline function r1() { return h1 - l1; }
	public inline function r2() { return h2 - l2; }
	
	/* conveniences */
	public static function pos(l, h, c) /*positive 0...1 mapping*/ { return new RangeMapping(l,h,0.,1.,c); }
	public static function neg(l, h, c) /*negative -1...1 mapping*/ { return new RangeMapping(l,h,-1.,1.,c); }
	
}
