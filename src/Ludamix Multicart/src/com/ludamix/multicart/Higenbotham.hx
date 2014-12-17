package com.ludamix.multicart;
import com.ludamix.multicart.d.Beeper;
import com.ludamix.multicart.d.InputConfig;
import com.ludamix.multicart.d.Proportion;
import com.ludamix.multicart.d.RangeMapping;
import haxe.ds.Vector;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.Lib;
import com.ludamix.multicart.d.Vec2F;

/*

	William Higenbotham's Tennis for Two.
	
	Wikipedia:
	
	Tennis For Two was an electronic game developed in 1958 on a Donner Model 30 analog computer, 
	which simulates a game of tennis or ping pong on an oscilloscope. 
	Created by American physicist William Higinbotham for visitors at the Brookhaven National Laboratory, 
	it is important in the history of video games as one of the first electronic games to use a graphical display.

	The original implementation of Tennis for Two used two customized controllers(understandibly) with a dial for angle,
	and a button to push the ball. There is no "paddle" or other representation of the player onscreen.
	
	Since some of the details of the game aren't readily available, I'm making my best guess of how the game plays based
	on observations of video and written information.
	
*/

enum BallState { Play(left_side /* ball possession variable */ : Bool); ServeL; ServeR; }

class Higenbotham implements MulticartGame
{
	
	public function new(){}
	
	public var inp /* input config and state */ : InputConfig;
	public var disp /* main display */ : Sprite;
	public var pfs /* playfield sprite */ : Sprite;
	public var ball : { v /*velocity*/ :Vec2F, p /*position*/ :Vec2F, s : BallState };
	public var angleL : Float; public var angleR : Float; /* player angles */
	public var hitL : Bool; public var hitR : Bool; /* player hits */
	public var vecL : Vec2F;  public var vecR : Vec2F; /* player displayed angles */
	public var hp : Float; /* hit power of volley */
	public var beep_gain : Vector<Float>; /* beeper gain */
	public var beep_freq : Array<Vector<Float>>; /* beeper freq */
	public static inline var PW /* playfield width */ = 150;
	public static inline var PH /* playfield height */ = 100;
	public static inline var NH /* net height (top y = PH-NH) */ = 20;
	public static inline var GRAVITY /* added to ball y per frame */ = 0.1;
	public static inline var BXR /* ball init x right */ = PW * 0.8;
	public static inline var BXL /* ball init x left */ = PW * 0.2;
	public static inline var BY /* ball init y */ = PH * 0.5;
	public static inline var HITPOW /* base hit power */ = 2.5;
	public static inline var HITINC /* add to hit power each hit */ = 0.1;
	public static inline var UIRAD /* player display radius */ = 32.;
	public static inline var UIRAD2 /* player display inner radius (circle) */ = 16.;
	
	public function start(inp : InputConfig)
	{
		{ /* init display */ disp = new Sprite(); Lib.current.stage.addChild(disp); }
		{ /* init playfield */ pfs = new Sprite(); disp.addChild(pfs); }
		{ /* init ball */ ball = { p:Vec2F.c(PW * 0.8, PH * 0.5), v:Vec2F.c(0., 0.), s:ServeR }; }
		{ /* init players */ angleL = 0.; angleR = -Math.PI; hitL = false; hitR = false; vecL = Vec2F.c(1, 0); vecR = Vec2F.c( -1, 0); }
		{ /* configure input */ this.inp = inp;
			inp.tfloat(ball.v, "x", RangeMapping.neg( -10, 10, 0.4), 0., "t0", "Ball X Vel", false);
			inp.tfloat(ball.v, "y", RangeMapping.neg( -10, 10, 0.4), 0., "t1", "Ball Y Vel", false);
			inp.tfloat(this, "angleL", RangeMapping.neg( -Math.PI / 2 + 0.03, Math.PI / 2 - 0.03, 1.), 0., "p0horiz", "Player 1 Angle", true);
			inp.tfloat(this, "angleR", RangeMapping.neg( -Math.PI * 3 / 2 + 0.03, -Math.PI / 2 - 0.03, 1.), 0., "p1horiz", "Player 2 Angle", true);
			inp.tbool(this, "hitL", false, "p0b0tap", "Player 1 Hit Ball");
			inp.tbool(this, "hitR", false, "p1b0tap", "Player 2 Hit Ball");
			inp.check(); if (inp.warn_t.length > 0) Main.error.s(inp.warn_t);
		}
		{ /* start audio */ Main.beeper.start(); 
			beep_freq = [Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) 440.]), Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) 220.])];
			beep_gain = Vector.fromArrayCopy([for (i in 0...Beeper.CK_SIZE) if (i < Beeper.CK_SIZE / 4) 1. -i / (Beeper.CK_SIZE / 4) else 0.]); 
		}
		{ /* start loop */ Lib.current.stage.addEventListener(Event.ENTER_FRAME, frame); }
	}
	
	public function hitSound(idx : Int) { Main.beeper.qg = [beep_gain]; Main.beeper.qf = [beep_freq[idx]]; }
	
	public function frame(ev : Event)
	{
		{ /* update inputs and refresh tuning */ for (i in 0...2) inp.refresh("t" + Std.string(i)); inp.poll(); 
			inp.refresh("p0horiz");
			inp.refresh("p1horiz");
		}
		{ /* simulate */
			vecL.ofRad(angleL); 
			vecR.ofRad(angleR); 
			var b = ball;
			switch(b.s)
			{
				case Play(left_side):
					/* gravity */ b.v.y += GRAVITY;
					/* bounce floor */ if (b.p.y + b.v.y > PH - 1) 
					{ /* push in then reverse */ b.p.y += b.v.y; b.v.y = -b.v.y; if (b.p.y + b.v.y > PH - 1) /* clamp if needed */ b.p.y = (PH - 1) - b.v.y;
					  if (Math.abs(b.v.y) <= GRAVITY) /* clamp to dead zone */ { b.v.y = 0.; } }
					/* bounce ceiling */ if (b.p.y + b.v.y < 0)
					{ /* push in then reverse */ b.p.y += b.v.y; b.v.y = -b.v.y; if (b.p.y + b.v.y < 0) /* clamp if needed */ 0 - b.v.y; }
					/* bounce net */ { var start = b.p.x < PW / 2; var end = b.p.x + b.v.x < PW / 2; 
						if (b.p.y + b.v.y > (PH - NH) - 1 && (start != end)) { b.v.x = -b.v.x; }
					}
					/* apply motion (euler integration) */ b.p.x += b.v.x; b.p.y += b.v.y;
					if (hitL && b.p.x <= PW / 2 && left_side) { ball.v.setfmul(vecL, hp); hp += HITINC; b.s = Play(false); hitSound(0); }
					if (hitR && b.p.x >= PW / 2 && !left_side) { ball.v.setfmul(vecR, hp); hp += HITINC; b.s = Play(true); hitSound(1); }
					if (b.p.x > PW) { b.s = ServeL; }
					if (b.p.x < 0) { b.s = ServeR; }
				case ServeL:
					b.p.x = BXL; b.p.y = BY; b.v.x = 0.; b.v.y = 0.; hp = HITPOW;
					if (hitL) { ball.v.setfmul(vecL, hp); hitSound(0); b.s = Play(false); }
				case ServeR:
					b.p.x = BXR; b.p.y = BY; b.v.x = 0.; b.v.y = 0.; hp = HITPOW;
					if (hitR) { ball.v.setfmul(vecR, hp); hitSound(1); b.s = Play(true); }
			}
			hitL = false; hitR = false;
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
			{ /* draw the playfield */
				var g = pfs.graphics; g.clear();
				g.lineStyle(2., 0xFFFFFFFF, 1.);
				/* ground */ g.moveTo(0,PH); g.lineTo(PW, PH);
				/* net */ g.moveTo(PW/2, PH); g.lineTo(PW/2, PH-NH);
				/* ball */ g.beginFill(0xFFFFFF, 1.); g.drawRect(ball.p.x, ball.p.y, 1., 1.); g.endFill();
			}
			{ /* draw the player input */
				var g = disp.graphics; 
				g.lineStyle(2, 0xFFFFFFFF, 1.); 
				var r = UIRAD; var ri = UIRAD2; var xL = r; var xR = Lib.current.stage.stageWidth - r;
				/* left */ g.drawCircle(xL, r, ri);  g.moveTo(xL, r); g.lineTo(xL + r * vecL.x, r + r * vecL.y);
				/* right */ g.drawCircle(xR, r, ri); g.moveTo(xR, r); g.lineTo(xR + r * vecR.x, r + r * vecR.y);
			}
		}
	}
	
	public function exit()
	{
		/* remove display */ Lib.current.stage.removeChild(disp);
		/* stop audio */ Main.beeper.stop();
		/* end loop */ Lib.current.stage.removeEventListener(Event.ENTER_FRAME, frame);
	}
	
}