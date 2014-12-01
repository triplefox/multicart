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

	Spacewar!

	Spacewar! was conceived in 1961 by Martin Graetz, Stephen Russell, and Wayne Wiitanen. 
	It was first realized on the PDP-1 in 1962 by Stephen Russell, Peter Samson, Dan Edwards, and Martin Graetz, 
	together with Alan Kotok, Steve Piner, and Robert A Saunders. 
	– Spacewar! is in the public domain, but this credit paragraph must accompany all distributed versions of the program.
	
	Like the various tennis games, Spacewar! is tied to a simple model of physical motion. Additionally, it features
	the new ideas of shooting projectiles, and direct control of a player avatar(the spaceship).

*/

class Spacewar implements MulticartGame
{
	
	public function new(){}
	
	public var inp /* input config and state */ : InputConfig;
	public var disp /* main display */ : Sprite;
	public var pfs /* playfield sprite */ : Sprite;
	public var players : Array<{ v /*velocity*/ :Vec2F, p /*position*/ :Vec2F, a /*angle*/ : Float, av /*angle velocity*/ : Float, o /*owner*/ : Int, l /*alive*/ : Bool }>;
	public var projectiles : Array<{ v /*velocity*/ :Vec2F, p /*position*/ :Vec2F, l /*alive*/ : Bool, o /*owner*/ : Int}>;
	public var controls : Array<{ f /*fire*/ :Bool, t /*thrust*/ :Bool, l /*left*/ :Bool, r /*right*/ :Bool, h /*hyperspace*/ :Bool }>;	
	public var beep_gain : Vector<Float>; /* beeper gain */
	public var beep_freq : Array<Vector<Float>>; /* beeper freq */
	public static inline var PW /* playfield width */ = 100;
	public static inline var PH /* playfield height */ = 100;
	public static inline var GRAVITY /* added to players each frame towards center of playfield(sun) */ = 0.1;
	public static inline var P0X /* player 0 init x */ = PW * 0.2;
	public static inline var P0Y /* player 0 init y */ = PH * 0.2;
	public static inline var P0A /* player 0 init angle */ = 0;
	public static inline var P1X /* player 1 init x */ = PW * 0.8;
	public static inline var P1Y /* player 1 init y */ = PH * 0.8;
	public static inline var P1A /* player 1 init angle */ = 0;
	
	public function start(inp : InputConfig)
	{
		{ /* init display */ disp = new Sprite(); Lib.current.stage.addChild(disp); }
		{ /* init playfield */ pfs = new Sprite(); disp.addChild(pfs); }
		{ /* init projectiles */ projectiles = [for (i in 0...100) {v:Vec2F.c(0.,0.), p:Vec2F.c(0.,0.), l:false, o:-1}]; }
		{ /* init players */ players = [ { v:Vec2F.c(0., 0.), p:Vec2F.c(P0X, P0Y), a:P0A, av:0., o:0, l:true },
										 { v:Vec2F.c(0., 0.), p:Vec2F.c(P1X, P1Y), a:P1A, av:0., o:1, l:true } ]; }
		{ /* configure input */ this.inp = inp;
			controls = [for (i in 0...2) {f:false,t:false,l:false,r:false,h:false } ];
			inp.tbool(controls[0], "t", false, "p1b1tap", "Player 1 Thrust");
			inp.tbool(controls[0], "l", false, "p1left", "Player 1 Left");
			inp.tbool(controls[0], "r", false, "p1right", "Player 1 Right");
			inp.tbool(controls[1], "t", false, "p2b1tap", "Player 2 Thrust");
			inp.tbool(controls[1], "l", false, "p2left", "Player 2 Left");
			inp.tbool(controls[1], "r", false, "p2right", "Player 2 Right");
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
		{ /* update inputs and refresh tuning */ inp.poll(); 
		}
		{ /* simulate */
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
				for (p in players) { if (p.l) { g.moveTo(p.p.x, p.p.y); g.lineTo(p.p.x + 1, p.p.y + 1); } }
				for (p in projectiles) { if (p.l) { g.moveTo(p.p.x, p.p.y); g.lineTo(p.p.x + 1, p.p.y + 1); } }
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