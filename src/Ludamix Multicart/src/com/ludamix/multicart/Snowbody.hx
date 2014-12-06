package com.ludamix.multicart;
import com.ludamix.multicart.d.Beeper;
import com.ludamix.multicart.d.InputConfig;
import com.ludamix.multicart.d.Proportion;
import com.ludamix.multicart.d.RangeMapping;
import haxe.ds.Vector;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;
import openfl.Lib;
import com.ludamix.multicart.d.Vec2F;

/*

	Digital Snowbody Game
	
	Task 1. Multi-part snowperson body rendering - rotozoomed bitmaps, I suppose
	Task 2. Introduce knobs to scale and skew things
	Task 3. Add animation things, export tools
	Task 4. Dump more stuff on (bitmap distort, bg color change, snowflake fx, etc.)
	
*/

class Snowbody implements MulticartGame
{
	
	public function new(){}
	
	public var inp /* input config and state */ : InputConfig;
	public var disp /* main display */ : Sprite;
	public var pfs /* playfield sprite */ : Bitmap;
	
	/*first ball origin*/ 
	public var snox : Float;
	public var snoy : Float;
	public var snow : Float;
	public var snoh : Float;
	/*offsets added per ball*/
	public var snax : Float;
	public var snay : Float;
	public var snaw : Float;
	public var snah : Float;
	public var bc /*count of balls*/ : Int;
	
	public var fe /*frames elapsed since start*/ : Int;
	public var ldt /*last delta time*/ : Float;
	public var mdt /*mean delta time*/ : Float;
	
	public var ballbmp /*ball base bitmap*/ : Bitmap;
	public var headbmp /*head base bitmap*/ : Bitmap;
	public var armbmp /*arm base bitmap*/ : Bitmap;
	public var flakebmp /*snowflake base bitmap*/ : Bitmap;
	
	public var beep_gain : Vector<Float>; /* beeper gain */
	public var beep_freq : Array<Vector<Float>>; /* beeper freq */
	
	public static inline var PW /* playfield width */ = 256;
	public static inline var PH /* playfield height */ = 256;
	
	public function start(inp : InputConfig)
	{
		{ /* init display */ disp = new Sprite(); Lib.current.stage.addChild(disp); }
		{ /* init playfield */ pfs = new Bitmap(new BitmapData(PW, PH)); disp.addChild(pfs); }
		{ /* init bitmaps */ var b = new BitmapData(256, 256, true, 0); b.perlinNoise(10., 10., 4, 0, false, true); bslice(b); }
		{ /* init timers */ fe = 0; ldt = Lib.getTimer(); mdt = 0.; }
		{ /* configure input */ this.inp = inp;
			inp.check(); if (inp.warn_t.length > 0) trace(inp.warn_t);
		}
		{ /* start audio */ Main.beeper.start(); 
			beep_freq = [Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) 440.]), Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) 220.])];
			beep_gain = Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) if (i < Beeper.CK_SIZE / 4) 1. -i / (Beeper.CK_SIZE / 4) else 0.]); 
		}
		{ /* start loop */ Lib.current.stage.addEventListener(Event.ENTER_FRAME, frame); }
	}
	
	public function frame(ev : Event)
	{
		{ /* update inputs and refresh tuning */ inp.poll();
		}
		{ /* simulate */
		}
		{ /* render */
			/* common parameters */
			var bg = 0xFF990099;
			{ /* draw the background and position the playfield */
				var sw = Lib.current.stage.stageWidth; var sh = Lib.current.stage.stageHeight;
				var g = disp.graphics; g.clear(); 
				g.lineStyle(0, 0, 0); g.beginFill(bg); g.drawRect(0., 0., sw, sh); g.endFill();
				/* position and scale the playfield */
				var sc = Proportion.bestfit(PW, PH, sw, sh);
				pfs.scaleX = sc; pfs.x = sw / 2 - PW*sc / 2; 
				pfs.scaleY = sc; pfs.y = sh / 2 - PH*sc / 2;
			}
			{ /* draw the playfield */
				pfs.bitmapData.fillRect(pfs.bitmapData.rect, 0xFF000000);
				var m = new Matrix();
				var d /*draw rotozoomed, colored bitmap*/ = function(bi : Int, xs : Float, ys : Float, r : Float, xt : Float, yt : Float,
					r0:Float, g0:Float, b0:Float, a0:Float, r1:Float, g1:Float, b1:Float, a1:Float) {
					var b = [ballbmp,headbmp,armbmp,flakebmp][bi];	
					m.identity(); m.translate( -b.width / 2, -b.height / 2); m.scale(xs, ys); m.rotate(r * Math.PI * 2.); m.translate(xt, yt);
					pfs.bitmapData.draw(b, m, new ColorTransform(r0, g0, b0, a0, r1*255, g1*255, b1*255, a1*255));
				}
				d(0, 0.5 + (fe / 100) % 1., 1., fe / 100, 128, 128, 1., 1., 1., 1., 0., 0., 0., 0.);
				d(0, 1., 0.5 + (fe / 100) % 1., fe / 100, 0, 128, 1., 1., 1., 1., (fe / 100) % 1, 0., 0., 0.);
				// ok, we're into the troublesome part now.
				// we have a model for displaying things...
				// but now we need to create and tune the actual synthesis algorithms
				// presumably we buffer up the data...
				// since we've reduced it to a "bunch of numbers" this isn't terribly hard.
				// but i will have to draw some actual art and put that in to know the default look and feel of the snowperson.
			}
		}
		{ /* end tick */
			/* increment frame */ fe+= 1; 
			/* update dt counts */ var dt = Lib.getTimer(); mdt = mdt * 0.9 + (dt - ldt) * 0.1; ldt = dt; 
			disp.graphics.beginFill(0xFF000000, 1.); disp.graphics.drawRect(0., 0., 2., mdt * 25); disp.graphics.endFill(); 
		}
	}
	
	public function exit()
	{
		/* remove display */ Lib.current.stage.removeChild(disp);
		/* stop audio */ Main.beeper.stop();
		/* end loop */ Lib.current.stage.removeEventListener(Event.ENTER_FRAME, frame);
	}
	
	public function bslice(ib : BitmapData) /* slice a bitmap into 2x2 smaller bitmaps */
	{
		var w = ib.width>>1; var h = ib.height>>1;
		ballbmp = new Bitmap(new BitmapData(w, h, true, 0));
		headbmp = new Bitmap(new BitmapData(w, h, true, 0));
		armbmp = new Bitmap(new BitmapData(w, h, true, 0));
		flakebmp = new Bitmap(new BitmapData(w, h, true, 0));
		ballbmp.bitmapData.copyPixels(ib, new Rectangle(0.,0.,w,h), new Point(0., 0.), null, null, true);
		headbmp.bitmapData.copyPixels(ib, new Rectangle(w,0.,w,h), new Point(0., 0.), null, null, true);
		armbmp.bitmapData.copyPixels(ib, new Rectangle(0.,h,w,h), new Point(0., 0.), null, null, true);
		flakebmp.bitmapData.copyPixels(ib, new Rectangle(w, h, w, h), new Point(0., 0.), null, null, true);
	}
	
}