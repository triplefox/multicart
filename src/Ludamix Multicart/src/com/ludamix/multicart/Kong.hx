package com.ludamix.multicart;
import com.ludamix.multicart.d.Beeper;
import com.ludamix.multicart.d.InputConfig;
import com.ludamix.multicart.d.Proportion;
import com.ludamix.multicart.d.RangeMapping;
import com.ludamix.multicart.d.T;
import haxe.ds.Vector;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Matrix;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;
import openfl.Lib;
import openfl.Assets;
import com.ludamix.multicart.d.Vec2F;

/*

	Kong

	Donkey Kong (1982)

*/

/* position */
/* entity type */
/* animation state */
/* velocity */

/* let's start with sprite rendering...  */

typedef SpriteAsset = {
	i : Int, /* id */
	s : Int, /* sheet id */
	rx : Int, /* rect x */
	ry : Int, /* rect y */
	rw : Int, /* rect w */
	rh : Int, /* rect h */
	_c : Rectangle, /* rectangle cache */
	f : Int, /* relative index of next anim frame */
	n : String /* name */
};

typedef SheetAsset = {
	i : Int, /* id */
	w : Int, /* width */
	h : Int, /* height */
	n : String, /* name */
	d : BitmapData /* data */
};

class Kong implements MulticartGame
{
	
	public function new(){}
	
	public var inp /* input config and state */ : InputConfig;
	public var disp /* main display */ : Sprite;
	public var pfs /* playfield sprite */ : Sprite;
	public var sbm /* screen bitmap */ : Bitmap;
	public var sbd /* screen bitmapdata */ : BitmapData;
	
	public var spra /* sprite assets */ : Array<SpriteAsset>;
	public var sprm /* sprite map */ : Map<String, Int>;
	public var shta /* sheet assets */ : Array<SheetAsset>;
	public var shtm /* sheet map */ : Map<String, Int>;
	
	public var shtplay : Int; /* sheet: play */
	public var sprhero : Int; /* sprite: hero */
	public var sprplat : Int; /* sprite: platform */
	
	public var dp0 : Point; /* draw point 0 */
	public var dp1 : Point; /* draw point 1 */
	
	public var hero : {p : Vec2F, v : Vec2F, a : Vec2F, j/*jump*/:Int};
	public var plat : Array<{p : Vec2F}>;
	
	public var beep_gain : Array<Vector<Float>>; /* beeper gain */
	public var beep_freq : Array<Vector<Float>>; /* beeper freq */
	
	public var controls : Array<{ j /*jump*/ :Bool, u /*up*/ :Bool, l /*left*/ :Bool, r /*right*/ :Bool, d /*down*/ :Bool }>;	
	
	public static inline var PW /* playfield width */ = 200;
	public static inline var PH /* playfield height */ = 200;
	public static inline var HEROW /* hero width */ = 16;
	public static inline var HEROH /* hero height */ = 16;
	public static inline var HEROSTEP /* hero step height */ = 4;
	public static inline var PLATW /* plat width */ = 8;
	public static inline var PLATH /* plat height */ = 8;
	
	public function loadSprites(name : String, data: Array<Array<Int>>) : Int {
		var ni = spra.length;
		for (di in 0...data.length) {
			var d = data[di];
			var f = (di == data.length - 1) ? -(data.length - 1) : 1; /* default linking: loop forward */
			spra.push( { i:ni+di, s:d[0], rx:d[1], ry:d[2], rw:d[3], rh:d[4], _c:new Rectangle(d[1],d[2],d[3],d[4]), f:f, 
			n:name
			} );
		}
		sprm.set( name, ni );
		return ni;
	}
	
	public function loadSheet(name : String, bd : BitmapData) : Int {
		var ni = shta.length;
		shta.push( {i:ni, w:bd.width, h:bd.height, n:name, d:bd} );
		shtm.set( name, ni );
		return ni;
	}
	
	public function clear() {
		sbd.fillRect(sbd.rect, 0);
	}
	
	public function blit(a /*asset*/ : Int, x : Int, y : Int) {
		var spr = spra[a]; dp0.x = x; dp0.y = y;
		sbd.copyPixels(shta[spr.s].d, spr._c, dp0, null, null, true);
	}
	
	public function start(inp : InputConfig)
	{
		{ /* init display */ disp = new Sprite(); Lib.current.stage.addChild(disp); }
		{ /* init playfield */ pfs = new Sprite(); disp.addChild(pfs); }
		{ /* init screen */ sbd = new BitmapData(PW, PH, false, 0); sbm = new Bitmap(sbd); pfs.addChild(sbm); }
		{ /* load assets */
			spra = []; shta = []; sprm = new Map(); shtm = new Map();
			shtplay = loadSheet("play", Assets.getBitmapData("img/kong/play.png"));
			sprhero = loadSprites("hero", [[shtplay, 0, 0, HEROW, HEROH]]);
			sprplat = loadSprites("plat", [[shtplay, 16, 0, PLATW, PLATH]]);
			dp0 = new Point(0., 0.);
			dp1 = new Point(0., 0.);
			plat = [];
			for (i0 in 0...16) {
				plat.push({p:Vec2F.c(16.+i0*8., PH-16.-2.*i0)});
			}
		}
		resetRound();
		{ /* configure input */ this.inp = inp;
			controls = [for (i in 0...1) { j:false, u:false, l:false, r:false, d:false } ];
			for (i in 0...1) {
				inp.tbool(controls[i], "j", false, 'p${i}b0tap', 'Player ${i} Jump');
				inp.tbool(controls[i], "l", false, 'p${i}lefthold', 'Player ${i} Left');
				inp.tbool(controls[i], "r", false, 'p${i}righthold', 'Player ${i} Right');
				inp.tbool(controls[i], "u", false, 'p${i}uphold', 'Player ${i} Up');
				inp.tbool(controls[i], "d", false, 'p${i}downhold', 'Player ${i} Down');
			}
			inp.check(); if (inp.warn_t.length > 0) Main.error.s(inp.warn_t);
		}
		{ /* start audio */ Main.beeper.start(); 
			beep_freq = [Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) 880 - i / Beeper.CK_SIZE * 879.]), 
						 Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) 440 - i / Beeper.CK_SIZE * 439.]),
						 Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) Math.random() * 220]),
						 Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) Math.random() * 20])];
			beep_gain = [Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) 1. - (i / (Beeper.CK_SIZE))]),
						 Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) 1. - (i / (Beeper.CK_SIZE)) / 2]),
						 Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) 0.5 - (i / (Beeper.CK_SIZE)) / 2])
						]; 
		}
		{ /* start loop */ Lib.current.stage.addEventListener(Event.ENTER_FRAME, frame); }
	}
	
	public function resetRound()
	{
		hero = {p:Vec2F.c(16.,16.),v:Vec2F.c(0.,0.),a:Vec2F.c(0.,0.),j:0};
	}
	
	public function aabb(x0:Float,y0:Float,w0:Float,h0:Float,x1:Float,y1:Float,w1:Float,h1:Float) {
		return !(x0 + w0 <= x1 || x0 > x1 + w1 || y0 + h0 <= y1 || y0 > y1 +h1);
	}
	
	public function shootSound(idx : Int) { Main.beeper.qg = [beep_gain[0]]; Main.beeper.qf = [beep_freq[idx]]; }
	public function hitSound() { Main.beeper.qg = [beep_gain[1],beep_gain[2]]; Main.beeper.qf = [beep_freq[2],beep_freq[3]]; }
	
	public function oob(v : Vec2F, z : Float) /*(-z,z+PW],(-z,z+PH]*/ { return v.x < -z || v.y < -z || v.x >= z+PW || v.y >= z+PH; }
	
	public function antidenormal(v : Vec2F) { v.x += 0.0000000001; v.y += 0.0000000001; v.x -= 0.0000000001; v.y -= 0.0000000001; }
	
	public function frame(ev : Event)
	{
		{ /* update inputs and refresh tuning */ inp.poll();
		}
		{ /* simulate */
			for (i in 0...controls.length)
			{
				if (hero.j > 0) { /* control when on ground */
					/* left and right */
					hero.v.x = 0.;
					if (controls[i].l) { hero.v.x = -1.5; }
					if (controls[i].r) { hero.v.x = 1.5; }
					/* jump */
					if (controls[i].j) { hero.v.y = -3.5; }
				}
			}
			
			hero.a.y = 0.2;
			//if (hero.j <= 0) hero.a.y = 0.5;
			
			hero.v.x += hero.a.x;
			hero.v.y += hero.a.y;
			
			hero.p.x += hero.v.x;
			hero.p.y += hero.v.y;
			
			hero.j = 0;
			if (hero.p.y + HEROH >= PH) { /* ground collision */
				hero.p.y = PH - HEROH; hero.j = 1; hero.v.y = 0.;
			}
			for (p in plat) { /* plat collision */
				if (hero.v.y >= 0 && aabb(hero.p.x, hero.p.y + HEROH - HEROSTEP, HEROW, HEROSTEP, p.p.x, p.p.y, PLATW, 1) ) { 
					hero.p.y = p.p.y - HEROH; hero.j = 1; hero.v.y = 0.;
				}
			}
			
			antidenormal(hero.p);
			antidenormal(hero.v);
			antidenormal(hero.a);
			
		}
		{ /* render */
			/* common parameters */
			var bg = 0xFF000000;
			{ /* draw the background and position the playfield */
				var sw = Lib.current.stage.stageWidth; var sh = Lib.current.stage.stageHeight;
				var g = disp.graphics; g.clear(); 
				g.lineStyle(0, 0, 0); g.beginFill(bg); g.drawRect(0., 0., sw, sh); g.endFill();
				/* position and scale the playfield */
				var sc = Proportion.bestfit(PW, PH, sw, sh);
				pfs.scaleX = sc; pfs.x = sw / 2 - PW*sc / 2; 
				pfs.scaleY = sc; pfs.y = sh / 2 - PH*sc / 2;
			}
			{ /* draw the screen (per-frame bitmap graphics) */
				clear();
				for (p in plat) {
					blit(sprplat, Math.round(p.p.x), Math.round(p.p.y));
				}
				blit(sprhero, Math.round(hero.p.x), Math.round(hero.p.y));
			}
		}
		{ /* update game state */
 		}
	}
	
	public function exit()
	{
		/* remove display */ Lib.current.stage.removeChild(disp);
		/* stop audio */ Main.beeper.stop();
		/* end loop */ Lib.current.stage.removeEventListener(Event.ENTER_FRAME, frame);
	}
	
}