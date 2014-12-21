package com.ludamix.multicart.d;
class Vec2F
{
	public var x : Float; public var y : Float; 
	public function new() { }
	public static inline function c(x, y) { var v = new Vec2F(); v.x = x; v.y = y; return v; }
	public inline function addf(v : Vec2F) { x += v.x; y += v.y; }
	public inline function setf(v : Vec2F) { x = v.x; y = v.y; }
	public inline function setfmul(v : Vec2F, s : Float) { x = v.x * s; y = v.y * s; }
	public inline function addfmul(v : Vec2F, s : Float) { x += v.x * s; y += v.y * s; }
	public inline function subf(v : Vec2F) { x -= v.x; y -= v.y; }
	public inline function mulf(v : Vec2F) { x *= v.x; y *= v.y; }
	public inline function divf(v : Vec2F) { x /= v.x; y /= v.y; }
	public inline function rad() /* radians (0 = (x=1, y=0)) */ { return Math.atan2(y, x); }
	public inline function mag() { return Math.sqrt(x*x+y*y); }
	public inline function ofRad(r : Float) { x = Math.cos(r); y = Math.sin(r); }
	public inline function ofRadmul(r : Float, m : Float) { x = Math.cos(r) * m; y = Math.sin(r) * m; }
	public inline function rot(r : Float) { ofRadmul(rad() + r, mag()); }
	public inline function clone() { return Vec2F.c(x, y); }
	
	public inline function lerp(a : Vec2F, b : Vec2F, z : Float) 
	{ x = a.x + (b.x - a.x) * z; y = a.y + (b.y - a.y) * z; }
	public inline function diff(a : Vec2F, b : Vec2F, z : Float) 
	{ x = (b.x - a.x) * z; y = (b.y - a.y) * z; }
	public static inline function distSqr(a : Vec2F, b : Vec2F) 
	{ var d0 = (a.x - b.x); var d1 = (a.y - b.y); return d0 * d0 + d1 * d1; }	
	public static inline function dist(a : Vec2F, b : Vec2F) 
	{ return Math.sqrt(distSqr(a, b)); }	
	
	public function toString() { return '(x ${Math.round(x*1000)/1000}, y ${Math.round(y*1000)/1000})'; }
	
}