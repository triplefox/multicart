package com.ludamix.multicart.d;

import openfl.media.Sound;
import openfl.events.SampleDataEvent;
import haxe.ds.Vector;

class Beeper
{
	
	/* basic scheduleable square wave generator with frequency and gain control running 32 times per frame (~345 times per second) */
	/* to use, push chunks of len CK_SIZE to qg(gain) and qf(frequency). */
	
	public static inline var CK_SIZE = 64;
	var snd : Sound; var oi /*oscillator index*/ : Int;
	/*empty gain & freq chunks*/ public static var eg : Vector<Float>; public static var ef : Vector<Float>; 
	/*queued gain & freq chunks*/ public var qg : Array<Vector<Float>>; public var qf : Array<Vector<Float>>;
	public function new() { oi = 0; qg = []; qf = [];
		eg = Vector.fromArrayCopy([for (i in 0...CK_SIZE) 0.]); ef = Vector.fromArrayCopy([for (i in 0...CK_SIZE) 440.]);
	}
	
	public function start() { snd = new Sound(); snd.addEventListener(flash.events.SampleDataEvent.SAMPLE_DATA, onSamples); snd.play(); }	
	public function stop() { snd.close(); snd.removeEventListener(flash.events.SampleDataEvent.SAMPLE_DATA, onSamples); snd = null; }	
	
	function onSamples(sde : SampleDataEvent)
	{
		var g = eg; var f = ef;
		if (qg.length > 0) g = qg.shift(); if (qf.length > 0) f = qf.shift();
		var c_mul = 1 / CK_SIZE;
		for (i in 0...4096)
		{
			var c /*chunk index*/ = Std.int(i * c_mul);
			var bw = 22050 / f[c]; /*bandwidth*/
			var osc = oi % bw > bw / 2 ? 1 : -1; /*oscillator raw output*/
			var r = osc * g[c]; /*gain control*/
			sde.data.writeFloat(r); sde.data.writeFloat(r); /*write to stereo buf*/
			oi += 1; /*advance osc*/
		}
	}	
	
}

