package com.ludamix.multicart;
import com.ludamix.multicart.d.InputConfig;
import com.ludamix.multicart.d.Proportion;
import com.ludamix.multicart.d.RangeMapping;
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

enum BallState { Play; ServeL; ServeR; }

class Higenbotham implements MulticartGame
{
	
	public function new(){}
	
	public var inp /* input config and state */ : InputConfig;
	public var disp /* main display */ : Sprite;
	public var pfs /* playfield sprite */ : Sprite;
	public var ball : { v /*velocity*/ :Vec2F, p /*position*/ :Vec2F, s : BallState };
	public var angleL : Float; public var angleR : Float; /* player angles */
	public var hitL : Bool; public var hitR : Bool; /* player hits */
	public static inline var PW /* playfield width */ = 150;
	public static inline var PH /* playfield height */ = 100;
	public static inline var NH /* net height (top y = PH-NH) */ = 20;
	public static inline var GRAVITY /* added to ball y per frame */ = 0.1;
	public static inline var BXR /* ball init x right */ = PW * 0.8;
	public static inline var BXL /* ball init x left */ = PW * 0.2;
	public static inline var BY /* ball init y */ = PH * 0.5;
	
	public function start(inp : InputConfig)
	{
		{ /* init display */ disp = new Sprite(); Lib.current.stage.addChild(disp); }
		{ /* init playfield */ pfs = new Sprite(); disp.addChild(pfs); }
		{ /* init ball */ ball = { p:Vec2F.c(PW * 0.8, PH * 0.5), v:Vec2F.c(0., 0.), s:ServeR }; }
		{ /* init players */ angleL = 0.; angleR = 0.; }
		{ /* configure input */ this.inp = inp;
			inp.tfloat(ball.v, "x", RangeMapping.neg( -10, 10, 0.4, 0.), 0., "float000", "Ball X Vel");
			inp.tfloat(ball.v, "y", RangeMapping.neg( -10, 10, 0.4, 0.), 0., "float001", "Ball Y Vel");
			inp.tfloat(this, "angleL", RangeMapping.neg( -90, 90, 1., 0.), 0., "p1horiz", "Player 1 Angle");
			inp.tfloat(this, "angleR", RangeMapping.neg( -90, 90, 1., 0.), 0., "p2horiz", "Player 2 Angle");
			inp.tbool(this, "hitL", false, "p1b1tap", "Player 1 Hit Ball");
			inp.tbool(this, "hitR", false, "p2b1tap", "Player 2 Hit Ball");
		}
		{ /* start loop */ Lib.current.stage.addEventListener(Event.ENTER_FRAME, frame); }
	}
	
	public function frame(ev : Event)
	{
		{ /* update inputs */ inp.refresh("p1horiz"); inp.refresh("p1vert"); inp.poll(); }
		{ /* simulate */
			var b = ball;
			//trace([hitL, hitR]);
			switch(b.s)
			{
				case Play:
					/* gravity */ b.v.y += GRAVITY;
					/* bounce */ if (b.p.y + b.v.y > PH - 1) 
					{ b.v.y = -b.v.y * 0.5; if (Math.abs(b.v.y)<=GRAVITY) /* clamp to dead zone */ { b.v.y = 0.; } }
					/* apply motion (euler integration) */ b.p.x += b.v.x; b.p.y += b.v.y;
					if (b.p.x > PW) { b.s = ServeL; }
					if (b.p.x < 0) { b.s = ServeR; }
				case ServeR:
					b.p.x = BXR; b.p.y = BY; b.v.x = 0.; b.v.y = 0.;
					if (hitR) b.s = Play;
				case ServeL:
					b.p.x = BXL; b.p.y = BY; b.v.x = 0.; b.v.y = 0.;
					if (hitL) b.s = Play;
			}
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
		}
	}
	
	public function exit()
	{
		/* remove display */ Lib.current.stage.removeChild(disp);
		/* end loop */ Lib.current.stage.removeEventListener(Event.ENTER_FRAME, frame);
	}
	
}