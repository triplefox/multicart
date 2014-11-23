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
	public inline function ofRad(r : Float) { x = Math.cos(r); y = Math.sin(r); }
	public inline function clone() { return Vec2F.c(x, y); }
}