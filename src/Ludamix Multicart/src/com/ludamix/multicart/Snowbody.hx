package com.ludamix.multicart;
import com.ludamix.multicart.d.Beeper;
import com.ludamix.multicart.d.InputConfig;
import com.ludamix.multicart.d.Proportion;
import com.ludamix.multicart.d.RangeMapping;
import com.ludamix.multicart.d.T;
import haxe.ds.Vector;
import lime.utils.Float32Array;
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
	
	Task 2. Introduce knobs to scale and skew things
	Task 3. Get away from the perlin noise placeholders somehow (maybe a thing to generate the bitmaps)
	Task 4. Dump more stuff on (bitmap distort, bg color change, snowflake fx, etc.)
	Task 5. Export functionality...
	
*/

typedef SpineVec = { p:Vec2F, r/*radians*/:Float, m/*magnitude*/:Float };
typedef Snowpart = { p/*position*/:Vec2F, v/*velocity*/:Vec2F, r/*radians*/:Float, rv/*radial velocity*/:Float, b/*bitmap*/:Int, 
	sw/*scale width*/:Float, sh/*scale height*/:Float };

class Snowbody implements MulticartGame
{
	
	public function new(){}
	
	public var inp /* input config and state */ : InputConfig;
	public var disp /* main display */ : Sprite;
	public var pfs /* playfield sprite */ : Bitmap;
	
	public var fe /*frames elapsed since start*/ : Int;
	public var ldt /*last delta time*/ : Float;
	public var mdt /*mean delta time*/ : Float;
	
	public var ballbmp /*ball base bitmap*/ : Bitmap;
	public var headbmp /*head base bitmap*/ : Bitmap;
	public var armbmp /*arm base bitmap*/ : Bitmap;
	public var flakebmp /*snowflake base bitmap*/ : Bitmap;
	
	public var parts : Array<Snowpart>;
	
	public var beep_gain : Vector<Float>; /* beeper gain */
	public var beep_freq : Array<Vector<Float>>; /* beeper freq */
	
	public var dir : Vec2F; /*temporary for direction*/
	
	public var explosion_damp : Float;
	
	/* inputs */
	public var trigger_explosion : Bool;
	
	/* constants */
	
	public static inline var PW /* playfield width */ = 256;
	public static inline var PH /* playfield height */ = 256;
	
	/* mapping of body parts to bitmaps */
	public static inline var PTBALL = 0;
	public static inline var PTHEAD = 1;
	public static inline var PTARM = 2;
	public static inline var PTFLAKE = 3;
	
	/* mapping of body parts to Snowpart instances */
	public static inline var SPLEG = 0;
	public static inline var SPCHEST = 1;
	public static inline var SPHEAD = 2;
	public static inline var SPARML = 3;
	public static inline var SPARMR = 4;
	
	private inline function lerpsv/*lerp SpineVec*/(a : SpineVec, b : SpineVec, z : Float) { 
		var p = Vec2F.c(0., 0.); p.lerp(a.p, b.p, z);
		var m = T.lerp(a.m, b.m, z);
		var r = T.lerpRad(a.r, b.r, z);
		return { p:p, m:m, r:r };
	}
	private inline function perpsv/*perpendicular of SpineVec*/(a : SpineVec) { 
		var p = a.p.clone();
		var m = a.m;
		var TAU = Math.PI * 2; var r = (a.r + Math.PI/2) % TAU;
		return { p:p, m:m, r:r };
	}
	
	public function start(inp : InputConfig)
	{
		{ /* init display */ disp = new Sprite(); Lib.current.stage.addChild(disp); }
		{ /* init playfield */ pfs = new Bitmap(new BitmapData(PW, PH)); disp.addChild(pfs); }
		{ /* init bitmaps */ var b = new BitmapData(256, 256, true, 0); b.perlinNoise(10., 10., 4, 0, false, true); bslice(b); }
		{ /* init timers */ fe = 0; ldt = Lib.getTimer(); mdt = 0.; }
		{ /* init parameter values */ 
			/*
			 * Spine description
			 * 
			 * total height
			 * 
			 * curvature function - trigonometric and iterative
			 * we compute 128 points using an angle-power metric
			 * then we sample from the points to generate the actual spine
			 * we can lerp from these points if needed...
			 * 
			 * this allows height to be preserved and also provides us with rotation values.
			 * 
			 * for arms, we also take a sample and then walk along the perpendiculars.
			 * so for this we need to do a decent amount of vector math
			 * 
			 * After doing this we draw directly from the samples.
			 * 
			 * Then we introduce state for each body part and lerp in.
			 * Oh...we will need rotational lerp anyway. Fuckit!
			 * 
			 * What we end up needing is cartesian vectors combined with angle-power indicators.
			 * 
			 * 
			 * */
			 
			// in that case we store some offset values in the code, as consts, and iterate over the set of initial offsets, scales,
			// bitmap types, etc.
			// more about animating, than it is about the distortion - we can ofc. perform distorts on the bitmap.
			
			// snowflakes get to be the special case since we do have reasons to make them more or less dense
			dir = Vec2F.c(0., 0.);
			parts = [];
			parts[SPLEG] = { p:Vec2F.c(0., 0.), v:Vec2F.c(0., 0.), r:0., rv:0., b:PTBALL, sw:1., sh:1. };
			parts[SPCHEST] = { p:Vec2F.c(0., 0.), v:Vec2F.c(0., 0.), r:0.,rv:0., b:PTBALL, sw:0.7, sh:0.7 };
			parts[SPHEAD] = { p:Vec2F.c(0., 0.), v:Vec2F.c(0., 0.), r:0.,rv:0., b:PTHEAD, sw:0.5, sh:0.5 };
			parts[SPARML] = { p:Vec2F.c(0., 0.), v:Vec2F.c(0., 0.), r:0.,rv:0., b:PTARM, sw:0.5, sh:0.5 };
			parts[SPARMR] = { p:Vec2F.c(0., 0.), v:Vec2F.c(0., 0.), r:0.,rv:0., b:PTARM, sw:0.5, sh:0.5 };
			for (p in parts) { p.p.x = Math.random() * PW; p.p.y = Math.random() * PH; p.r = Math.random() * Math.PI * 2; }
		}
		{ /* special effects parameters */
			explosion_damp = 0.;
		}
		{ /* configure input */ this.inp = inp;
			inp.check(); if (inp.warn_t.length > 0) trace(inp.warn_t);
			inp.tbool(this, "trigger_explosion", false, 'p0b0tap', 'Explode');
		}
		{ /* start loop */ Lib.current.stage.addEventListener(Event.ENTER_FRAME, frame); }
	}
	
	private inline function grc /*generate render command*/(bi : Int, xs : Float, ys : Float, r : Float, xt : Float, yt : Float,
		r0 : Float, g0 : Float, b0 : Float, a0 : Float, r1 : Float, g1 : Float, b1 : Float, a1 : Float) : Array<Float>
	{
		return [bi /*bitmap index*/, xs/*x scale*/, ys/*y scale*/, r/*rotation(0-1)*/, xt/*x translate*/, yt/*y translate*/, 
			r0/*red mult*/, g0/*green mult*/, b0/*blue mult*/, a0/*alpha mult*/, r1/*red add*/, g1/*green add*/, b1/*blue add*/, a1/*alpha add*/];
	}
	
	private inline function gdc /*generate debug command*/(x : Float, y : Float) { return [x, y]; }
	
	private function renderSpine(spine : Array<SpineVec>, POINTS : Int, ba : Array<Array<Float>>, ra : Array<Array<Float>>,
		rinc : Float, /* increment r per */
		minc : Float, /* increment m per */
		rsamp : Float, /* cos r amplitude */
		rsoff : Float, /* cos r offset */
		msamp : Float, /* cos m amplitude */
		msoff : Float /* cos m offset */
	)
	{
		var TAU = Math.PI * 2;
		var cur : SpineVec = spine[0]; var cr = cur.r; var cm = cur.m;
		for (i in 0...POINTS) /* create spine samples */
		{
			var pct = i / POINTS;
			var rampf /* r amp frame */ = Math.cos((pct + rsoff) * TAU) * rsamp;
			var mampf /* m amp frame */ = Math.cos((pct + msoff) * TAU) * msamp;
			var next = { p:cur.p.clone(), m:cm + mampf, r:cr + rampf };
			dir.ofRadmul(next.r, next.m); next.p.addf(dir);
			cr += rinc; cm += minc;
			spine.push(next); cur = next;
		}
		for (n in spine)
		{
			ba.push(gdc(n.p.x, n.p.y));
		}
	}
	
	private function simPart(pt : Snowpart, p : Vec2F, r : Float)
	{
		{ /* add spring forces */
			var POS_RATE = 0.02 * ( 1 - explosion_damp );
			var ROT_RATE = 0.01 * ( 1 - explosion_damp );
			var v = Vec2F.c(0., 0.); v.diff(pt.p, p, POS_RATE); pt.v.addf(v);
			pt.rv += T.diffRad(pt.r, r) * ROT_RATE;
		}
		{ /* add velocity */
			pt.p.addf(pt.v);
			pt.r = (pt.r + pt.rv) % (Math.PI * 2);
		}
		{ /* apply friction */
			var FRICT_RATE = 0.5;
			pt.v.mulf(Vec2F.c(FRICT_RATE, FRICT_RATE));
			pt.rv *= FRICT_RATE;
		}
	}
	
	public function frame(ev : Event)
	{
		{ /* update inputs and refresh tuning */ inp.poll();
			if (trigger_explosion)
			{
				for (p in parts) { 
					p.v.ofRadmul(Math.random() * Math.PI * 2, Math.random() * 50 + 50); 
					p.rv = Math.random() * 100 - 50; }
				explosion_damp = 1.;
			}
			trigger_explosion = false;
		}
		var ra /*render command array*/ = new Array<Array<Float>>();
		var ba /*debug point array*/ = new Array<Array<Float>>();
		{ /* simulate */
		
			var body = new Array<SpineVec>(); body.push({p:Vec2F.c(PW*0.5,PH*0.95),r:-Math.PI/2,m:1.5});
			
			renderSpine(body, 128, ba, ra, 0., 0., 0.5, fe/100, 0., fe/50);
			var samples = [for (i in [0.05, 0.5, 0.95]) T.sample(body, i)];
			
			simPart(parts[SPLEG], samples[0].p, samples[0].r);
			simPart(parts[SPCHEST], samples[1].p, samples[1].r);
			simPart(parts[SPHEAD], samples[2].p, samples[2].r);
			
			var armr = [perpsv(T.sample(body, 0.5))]; armr[0].m = 0.8;
			renderSpine(armr, 128, ba, ra, 0., 0., 0.1, fe/100, 0., fe/50);
			var arml = [{m:armr[0].m,r:armr[0].r+Math.PI,p:armr[0].p.clone()}];
			renderSpine(arml, 128, ba, ra, 0., 0., 0.1, fe/100, 0., fe/50);
			
			var arms = T.sample(armr, 0.8); simPart(parts[SPARMR], arms.p, arms.r);
			var arms = T.sample(arml, 0.8); simPart(parts[SPARML], arms.p, arms.r);
			
			for (p in parts)
			{
				ra.push(grc(p.b, p.sw, p.sh, p.r, p.p.x, p.p.y, 1., 1., 1., 1., 0., 0., 0., 0.));
			}
			
			explosion_damp = Math.max(0., explosion_damp * 0.99);
			
			//ra.push(grc(0, 0.05, 0.05, n.r, n.p.x, n.p.y, 1., 1., 1., 1., 0., 0., 0., 0.));
			//ra.push(grc(0, sncw, snch, 0., sncx, sncy, 1., 1., 1., 1., 0., 0., 0., 0.));
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
				pfs.bitmapData.lock();
				pfs.bitmapData.fillRect(pfs.bitmapData.rect, 0xFF000000);
				var m = new Matrix();
				for (n in ra) /* draw scaled, rotozoomed, colored bitmaps */
				{
					var bi = Std.int(n[0]); var xs = n[1]; var ys = n[2]; var r = n[3]; var xt = n[4]; var yt = n[5];
					var r0 = n[6]; var g0 = n[7]; var b0 = n[8]; var a0 = n[9]; var r1 = n[10]; var g1 = n[11]; var b1 = n[12]; var a1 = n[13];
					var b = [ballbmp,headbmp,armbmp,flakebmp][bi];
					m.identity(); m.translate( -b.width / 2, -b.height / 2); m.scale(xs, ys); m.rotate(r); m.translate(xt, yt);
					pfs.bitmapData.draw(b, m, new ColorTransform(r0, g0, b0, a0, r1*255, g1*255, b1*255, a1*255));
				}
				for (n in ba)
				{
					pfs.bitmapData.setPixel32(Math.round(n[0]), Math.round(n[1]), 0xFFFFFFFF);
				}
				pfs.bitmapData.unlock();
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