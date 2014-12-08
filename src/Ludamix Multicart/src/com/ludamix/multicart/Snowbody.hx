package com.ludamix.multicart;
import com.ludamix.multicart.d.Beeper;
import com.ludamix.multicart.d.InputConfig;
import com.ludamix.multicart.d.Knob;
import com.ludamix.multicart.d.Proportion;
import com.ludamix.multicart.d.RangeMapping;
import com.ludamix.multicart.d.T;
import com.ludamix.multicart.d.Tuner;
import haxe.ds.Vector;
import lime.utils.Float32Array;
import openfl.Assets;
import openfl.events.MouseEvent;
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
	
	Task 4. Dump more stuff on (bitmap distort, bg color change, snowflake fx, etc.)

		Categories
			Effects options	
			Sample point adjustments
			Bg adjust
			
			Resets for: spines, flakes, colors and scale
			Import image
			(do as button inputs?)
			
			Colorize knobs by group?
		
	Task 5. Export functionality...
	
*/

typedef ColorConfig = { rm:Float, gm:Float, bm:Float, am:Float, ro:Float, go:Float, bo:Float, ao:Float };
typedef SpineVec = { p:Vec2F, r/*radians*/:Float, m/*magnitude*/:Float };
typedef Snowpart = { p/*position*/:Vec2F, v/*velocity*/:Vec2F, r/*radians*/:Float, rv/*radial velocity*/:Float, b/*bitmap*/:Int, 
	sw/*scale width*/:Float, sh/*scale height*/:Float, col : ColorConfig };
	
typedef SpineConfig = { rinc : Float, /* increment r per */ 
		minc : Float, /* increment m per */ 
		rsamp : Float, /* cos r amplitude */
		rsoff : Float, /* cos r offset */ 
		msamp : Float, /* cos m amplitude */ 
		msoff : Float, /* cos m offset */
		ipx : Float, /* initial x offset */
		ipy : Float, /* initial y offset */
		ir : Float, /* initial radians */
};

class Snowbody implements MulticartGame
{
	
	public function new(){}
	
	public var inp /* input config and state */ : InputConfig;
	public var disp /* main display */ : Sprite;
	public var pfs /* playfield sprite */ : Bitmap;
	public var clicker /* clicker sprite - captures mouse events */ : Sprite;
	
	public var fe /*frames elapsed since start*/ : Int;
	public var ldt /*last delta time*/ : Float;
	public var mdt /*mean delta time*/ : Float;
	
	public var ballbmp /*ball base bitmap*/ : Bitmap;
	public var headbmp /*head base bitmap*/ : Bitmap;
	public var armbmp /*arm base bitmap*/ : Bitmap;
	public var flakebmp /*snowflake base bitmap*/ : Bitmap;
	
	public var parts : Array<Snowpart>;
	public var flakecolors : ColorConfig;
	
	public var dir : Vec2F; /*temporary for direction*/
	
	public var explosion_damp : Float;
	
	public var tuners : Array<Tuner>;
	public var knobs : Array<Knob>;
	
	public var sfp /*snowfield pattern*/ : {
		/*tile width and height*/ TW : Float, TH : Float,
		/*rotation velocity*/ RV : Float,
		/*flake width and height */ FW : Float, FH : Float,
		/*group mod depth and frequency */ GM : Float, GF : Float,
		/*per-flake mod depth */ FX : Float, FY : Float, FS : Float,
		/*pattern x frequency, depth */ PF : Float, PDX : Float,
		/*pattern y depth */ PDY : Float
	};
	public var body_s /*body spine*/ : SpineConfig;
	public var arm_s /*arm spine*/ : SpineConfig;
	
	/* inputs */
	public var trigger_explosion : Bool;
	public var draw_debug : Bool;
	
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
		{ /* init clicker */ clicker = new Sprite(); disp.addChild(clicker); 
			var g = clicker.graphics; g.beginFill(0, 0.); g.drawRect(0., 0., Lib.current.stage.width, Lib.current.stage.height); g.endFill();
			clicker.mouseEnabled = true; clicker.mouseChildren = true;
			for (e in [MouseEvent.CLICK, MouseEvent.MOUSE_MOVE, MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_UP,
			MouseEvent.MOUSE_OVER, MouseEvent.MOUSE_OUT, MouseEvent.RELEASE_OUTSIDE])
				Lib.current.stage.addEventListener(e, onClicker);
		}
		{ /* init bitmaps */ var b = Assets.getBitmapData("img/snowbody/texture.png"); bslice(b); }
		{ /* init timers */ fe = 0; ldt = Lib.getTimer(); mdt = 0.; }
		{ /* init parameter values */ 
			/*
			 * Spine description
			 * 
			 * preserve a "total height" so that spine feels natural
			 * 
			 * curvature function - trigonometric and iterative
			 * we compute 128 points using an angle-power metric
			 * then we sample from the points to generate the actual spine
			 * this allows height to be preserved and also provides us with rotation values.
			 * for arms, we also take a sample and then walk along the perpendiculars.
			 * After doing this we introduce state for each body part and lerp into the sample points.
			 * 
			 * */
			dir = Vec2F.c(0., 0.);
			parts = [];
			parts[SPLEG] = { p:Vec2F.c(0., 0.), v:Vec2F.c(0., 0.), r:0., rv:0., b:PTBALL, sw:1., sh:1., col:null };
			parts[SPCHEST] = { p:Vec2F.c(0., 0.), v:Vec2F.c(0., 0.), r:0.,rv:0., b:PTBALL, sw:0.7, sh:0.7, col:null };
			parts[SPHEAD] = { p:Vec2F.c(0., 0.), v:Vec2F.c(0., 0.), r:0.,rv:0., b:PTHEAD, sw:0.5, sh:0.5, col:null };
			parts[SPARML] = { p:Vec2F.c(0., 0.), v:Vec2F.c(0., 0.), r:0.,rv:0., b:PTARM, sw:0.5, sh:0.5, col:null };
			parts[SPARMR] = { p:Vec2F.c(0., 0.), v:Vec2F.c(0., 0.), r:0.,rv:0., b:PTARM, sw:0.5, sh:0.5, col:null };
			for (p in parts) { p.p.x = Math.random() * PW; p.p.y = Math.random() * PH; p.r = Math.random() * Math.PI * 2; 
				p.col = { rm:1., gm:1., bm:1., am:1., ro:0., go:0., bo:0., ao:0. };
			}
			
			sfp = {/*tile width and height*/ TW : 64, TH : 64,
			/*rotation velocity*/ RV : 0.02,
			/*flake width and height */ FW : 0.1, FH : 0.1,
			/*group mod depth and frequency */ GM : 64, GF : 1/50,
			/*per-flake mod depth */ FX : 1 / 12, FY : 1 / 8, FS : 2,
			/*pattern x frequency, depth */ PF : 1 / 128, PDX : 64,
			/*pattern y depth */ PDY : 0.5
			};
			
			body_s = { rinc : 0., /* increment r per */ 
					minc : 0., /* increment m per */ 
					rsamp : 0.5, /* cos r amplitude */
					rsoff : 1/100, /* cos r offset */ 
					msamp : 0., /* cos m amplitude */ 
					msoff : 1/50, /* cos m offset */
					ipx : 0.,
					ipy : 0.,
					ir : 0.
			};
			arm_s = { rinc : 0., /* increment r per */ 
					minc : 0., /* increment m per */ 
					rsamp : 0.5, /* cos r amplitude */
					rsoff : 1/100, /* cos r offset */ 
					msamp : 0., /* cos m amplitude */ 
					msoff : 1/50, /* cos m offset */
					ipx : 0.,
					ipy : 0.,
					ir : 0.
			};
			flakecolors = {rm:1.,gm:1.,bm:1.,am:1.,ro:0.,go:0.,bo:0.,ao:0.};
		}
		{ /* special effects parameters */
			explosion_damp = 0.;
			
			tuners = [Tuner.makeFloat(this, "explosion_damp", RangeMapping.pos(0., 1., 0.3, 0.), 0., "", "", true),
				Tuner.makeFloat(sfp, "FW", RangeMapping.pos(0.01,1.0,1.,0.1), 0.1, "", "", true),
				Tuner.makeFloat(sfp, "FH", RangeMapping.pos(0.01,1.0,1.,0.1), 0.1, "", "", true),
				Tuner.makeFloat(sfp, "FX", RangeMapping.pos(0.001,16.,1/4,1/12), 1/12, "", "", true),
				Tuner.makeFloat(sfp, "FY", RangeMapping.pos(0.001,16.,1/4,1/8), 1/8, "", "", true),
				Tuner.makeFloat(sfp, "FS", RangeMapping.neg(-16.,16.,1/4,2.), 2., "", "", true),
				Tuner.makeFloat(sfp, "GF", RangeMapping.pos(0.001,32.,1/4,64), 64, "", "", true),
				Tuner.makeFloat(sfp, "GM", RangeMapping.neg(-128,128.,1/4,1/50), 1/50, "", "", true),
				Tuner.makeFloat(sfp, "TW", RangeMapping.neg(24.,256.,1/4,64), 64, "", "", true),
				Tuner.makeFloat(sfp, "TH", RangeMapping.neg(24.,256.,1/4,64), 64, "", "", true),
				Tuner.makeFloat(sfp, "PF", RangeMapping.pos(0.001,32,1/4,1/128), 1/128, "", "", true),
				Tuner.makeFloat(sfp, "PDX", RangeMapping.pos(0.,128,1/4,64), 64, "", "", true),
				Tuner.makeFloat(sfp, "PDY", RangeMapping.pos(0., 128, 1 / 4, 0.5), 0.5, "", "", true),
				Tuner.makeFloat(sfp, "RV", RangeMapping.pos(0., 1., 1 / 4, 0.02), 0.02, "", "", true),
			];
			for (a in [body_s, arm_s])
			{
				tuners = tuners.concat([
					Tuner.makeFloat(a, "rinc", RangeMapping.neg(-Math.PI*2, Math.PI*2, 1/4, 0.), 0., "", "", true),
					Tuner.makeFloat(a, "minc", RangeMapping.neg(-3., 3., 1/4, 0.), 0., "", "", true),
					Tuner.makeFloat(a, "rsamp", RangeMapping.neg(-10, 10., 1/4, 0.5), 0.5, "", "", true),
					Tuner.makeFloat(a, "rsoff", RangeMapping.pos(0.0001, 4., 1/4, 1/100), 1/100, "", "", true),
					Tuner.makeFloat(a, "msamp", RangeMapping.neg(-10, 10., 1/4, 0.), 0., "", "", true),
					Tuner.makeFloat(a, "msoff", RangeMapping.pos(0.0001, 4., 1/4, 1/50), 1/50, "", "", true),
					Tuner.makeFloat(a, "ipx", RangeMapping.neg(-256, 256, 1/4, 0.), 0., "", "", true),
					Tuner.makeFloat(a, "ipy", RangeMapping.neg(-256, 256, 1/4, 0.), 0., "", "", true),
					Tuner.makeFloat(a, "ir", RangeMapping.neg(-Math.PI, Math.PI, 1., 0.), 0., "", "", true),
				]);
			}
			for (a in parts)
			{
				tuners = tuners.concat([
					Tuner.makeFloat(a, "sw", RangeMapping.pos(0.001, 8, 1/4, 1.), 1., "", "", true),
					Tuner.makeFloat(a, "sh", RangeMapping.pos(0.001, 8, 1/4, 1.), 1., "", "", true),
					Tuner.makeFloat(a.col, "rm", RangeMapping.pos(0., 1., 1/4, 1.), 1., "", "", true),
					Tuner.makeFloat(a.col, "gm", RangeMapping.pos(0., 1., 1/4, 1.), 1., "", "", true),
					Tuner.makeFloat(a.col, "bm", RangeMapping.pos(0., 1., 1/4, 1.), 1., "", "", true),
					Tuner.makeFloat(a.col, "am", RangeMapping.pos(0., 1., 1/4, 1.), 1., "", "", true),
					Tuner.makeFloat(a.col, "ro", RangeMapping.neg(-5, 5, 1/4, 0.), 0., "", "", true),
					Tuner.makeFloat(a.col, "go", RangeMapping.neg(-5, 5, 1/4, 0.), 0., "", "", true),
					Tuner.makeFloat(a.col, "bo", RangeMapping.neg(-5, 5, 1/4, 0.), 0., "", "", true),
					Tuner.makeFloat(a.col, "ao", RangeMapping.neg(-5, 5, 1/4, 0.), 0., "", "", true),
				]);
			}
			tuners = tuners.concat([
					Tuner.makeFloat(flakecolors, "rm", RangeMapping.pos(0., 1., 1/4, 1.), 1., "", "", true),
					Tuner.makeFloat(flakecolors, "gm", RangeMapping.pos(0., 1., 1/4, 1.), 1., "", "", true),
					Tuner.makeFloat(flakecolors, "bm", RangeMapping.pos(0., 1., 1/4, 1.), 1., "", "", true),
					Tuner.makeFloat(flakecolors, "am", RangeMapping.pos(0., 1., 1/4, 1.), 1., "", "", true),
					Tuner.makeFloat(flakecolors, "ro", RangeMapping.neg(-5, 5, 1/4, 0.), 0., "", "", true),
					Tuner.makeFloat(flakecolors, "go", RangeMapping.neg(-5, 5, 1/4, 0.), 0., "", "", true),
					Tuner.makeFloat(flakecolors, "bo", RangeMapping.neg(-5, 5, 1/4, 0.), 0., "", "", true),
					Tuner.makeFloat(flakecolors, "ao", RangeMapping.neg(-5, 5, 1/4, 0.), 0., "", "", true),			
			]);
			knobs = [for (t in tuners) new Knob(32., t)];
			for (k in knobs) { clicker.addChild(k); }
		}
		{ /* configure input */ this.inp = inp;
			inp.check(); if (inp.warn_t.length > 0) trace(inp.warn_t);
			inp.tbool(this, "trigger_explosion", false, 'p0b0tap', 'Explode');
			inp.tbool(this, "draw_debug", false, 'p0b1hold', 'Draw Debug Infos');
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
		msoff : Float, /* cos m offset */
		ipx : Float,
		ipy : Float,
		ir : Float
	)
	{
		var TAU = Math.PI * 2;
		var cur : SpineVec = spine[0]; var cm = cur.m; cur.p.x += ipx; cur.p.y += ipy; cur.r += ir;
		var cr = cur.r; 
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
		if (draw_debug)
		{
			for (n in spine) /* debug draw */
			{
				ba.push(gdc(n.p.x, n.p.y));
			}
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
			{ // layout knobs at stage left and right
				var lx = 0.; var ly = 0.; var bx = 0.; var wlim = pfs.x;
				for (k in knobs) { k.x = lx; k.y = ly; lx += k.width+1; 
					if (lx + k.width + 1 > wlim) { 
						ly += k.height + 1; 
						if (ly + k.height + 1 > Lib.current.stage.stageHeight) { bx = pfs.x + pfs.width; ly = 0; wlim = Lib.current.stage.stageWidth; } 
						lx = bx; } 
					}
			}
			for (k in knobs) { if (!k.vg && k.tuner.refresh()) k.dirty = true; k.render(); }
		}
		var ra /*render command array*/ = new Array<Array<Float>>();
		var ba /*debug point array*/ = new Array<Array<Float>>();
		{ /* simulate */
		
			{ /* generate snowflake pattern */
				/*tile width and height*/ var TW = sfp.TW; var TH = sfp.TH;
				/*rotation velocity*/ var RV = sfp.RV;
				/*flake width and height */ var FW = sfp.FW; var FH = sfp.FH;
				/*group mod depth and frequency */ var GM = sfp.GM; var GF = sfp.GF;
				/*per-flake mod depth */ var FX = sfp.FX; var FY = sfp.FY; var FS = sfp.FS;
				/*pattern x frequency, depth */ var PF = sfp.PF; var PDX = sfp.PDX;
				/*pattern y depth */ var PDY = sfp.PDY;
			
				var bx : Float = (Math.sin(fe*PF) * PDX) % TW - TW; var by : Float = (fe * PDY) % TH - TH; /* flakes assume a basic tile pattern */
				bx = (bx + Math.sin(fe * GF) * GM);
				var x = bx; var y = by;
				var r = (fe * RV) % (Math.PI * 2);
				var rm = flakecolors.rm; var gm = flakecolors.gm; var bm = flakecolors.bm; var am = flakecolors.am;
				var ro = flakecolors.ro; var go = flakecolors.go; var bo = flakecolors.bo; var ao = flakecolors.ao;
				while (y < PH + TH)
				{
					ra.push(grc(PTFLAKE, FW, FH, r, x, y + Math.sin((y*FX-x*FY))*FS, rm, gm, bm, am, ro, go, bo, ao));
					x += TW; if (x > PW + TW) { x = bx % TW; y += TH; }
				}
			}
			
			/* body origin */
			var body = new Array<SpineVec>(); body.push({p:Vec2F.c(PW*0.5,PH*0.95),r:-Math.PI/2,m:1.5});
			
			/* render and sample spines */
			renderSpine(body, 128, ba, ra, body_s.rinc, body_s.minc, body_s.rsamp, fe * body_s.rsoff, body_s.msamp, fe * body_s.msoff,
				body_s.ipx, body_s.ipy, body_s.ir);
			var samples = [for (i in [0.05, 0.5, 0.95]) T.sample(body, i)];
			var armr = [perpsv(T.sample(body, 0.5))]; armr[0].m = 0.8;
			var arml = [{m:armr[0].m,r:armr[0].r+Math.PI,p:armr[0].p.clone()}];
			renderSpine(armr, 128, ba, ra, arm_s.rinc, arm_s.minc, arm_s.rsamp, fe * arm_s.rsoff, arm_s.msamp, fe * arm_s.msoff,
				arm_s.ipx, arm_s.ipy, arm_s.ir);
			renderSpine(arml, 128, ba, ra, arm_s.rinc, arm_s.minc, arm_s.rsamp, fe * arm_s.rsoff, arm_s.msamp, fe * arm_s.msoff,
				-arm_s.ipx, -arm_s.ipy, -arm_s.ir);
			samples.push(T.sample(armr, 0.8));
			samples.push(T.sample(arml, 0.8));
			
			{ /* physics sim for body parts */
				var i = 0;
				for (pi in [SPLEG, SPCHEST, SPHEAD, SPARMR, SPARML])
				{
					var pt = parts[pi]; var p = samples[i].p; var r = samples[i].r;
					{ /* add spring forces */
						var POS_RATE = 0.05 * ( 1 - explosion_damp );
						var ROT_RATE = 0.025 * ( 1 - explosion_damp );
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
					i+=1;
				}
			}
			
			for (p in parts) /* render graphics data */
			{
				ra.push(grc(p.b, p.sw, p.sh, p.r, p.p.x, p.p.y, p.col.rm, p.col.gm, p.col.bm, p.col.am, p.col.ro, p.col.go, p.col.bo, p.col.ao));
			}
			
			explosion_damp = Math.max(0., explosion_damp * 0.99);
			
		}
		{ /* render */
			/* common parameters */
			var bg = 0xFF222222;
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
					pfs.bitmapData.setPixel32(Math.round(n[0]), Math.round(n[1]), 0xFFFF8888);
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
		/* remove clicker */ for (e in [MouseEvent.CLICK, MouseEvent.MOUSE_MOVE, MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_UP,
			MouseEvent.MOUSE_OVER, MouseEvent.MOUSE_OUT, MouseEvent.RELEASE_OUTSIDE])
			Lib.current.stage.removeEventListener(e, onClicker);
		/* remove knobs */ for (k in knobs) k.uninit();
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
	
	public function onClicker(event : MouseEvent)
	{
		for (k in knobs)
		{
			if (k.vg) { k.onMouse(event); break; }
		}
	}
	
}