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

class Higenbotham implements MulticartGame
{
	
	public function new(){}
	
	public var inp /* input config and state */ : InputConfig;
	public var disp /* main display */ : Sprite;
	public var pfs /* playfield sprite */ : Sprite;
	public var ball : {v /*velocity*/ :Vec2F, p /*position*/ :Vec2F, live :Bool};
	public static inline var PW /* playfield width */ = 150;
	public static inline var PH /* playfield height */ = 100;
	public static inline var NH /* net height (top y = PH-NH) */ = 20;
	public static inline var GRAVITY /* added to ball y per frame */ = 0.1;
	public static inline var BX /* ball init x */ = PW * 0.8;
	public static inline var BY /* ball init y */ = PH * 0.5;
	
	public function start(inp : InputConfig)
	{
		{ /* init display */ disp = new Sprite(); Lib.current.stage.addChild(disp); }
		{ /* init playfield */ pfs = new Sprite(); disp.addChild(pfs); }
		{ /* init ball */ ball = { p:Vec2F.c(PW * 0.8, PH * 0.5), v:Vec2F.c(0., 0.), live:false }; }
		{ /* configure input */ this.inp = inp;
			inp.tfloat(ball.v, "x", RangeMapping.neg( -2, 2, 1., 0.), 0., "horiz", "Ball X Vel");  
			inp.tfloat(ball.v, "y", RangeMapping.neg( -2, 2, 1., 0.), 0., "vert", "Ball Y Vel");  
		}			
		{ /* start loop */ Lib.current.stage.addEventListener(Event.ENTER_FRAME, frame); }
	}
	
	public function frame(ev : Event)
	{
		{ /* update inputs */ inp.refresh("horiz"); inp.refresh("vert"); inp.poll(); }
		{ /* simulate */
			var b = ball;
			if (b.live)
			{
				/* gravity */ b.v.y += GRAVITY;
				/* bounce */ if (b.p.y + b.v.y > PH - 1) 
				{ b.v.y = -b.v.y * 0.5; if (Math.abs(b.v.y)<=GRAVITY) /* clamp to dead zone */ { b.v.y = 0.; } }
				/* apply motion (euler integration) */ b.p.x += b.v.x; b.p.y += b.v.y;
				if (b.p.x > PW) { b.live = false; }
				if (b.p.x < 0) { b.live = false; }
			}
			else
			{
				// TODO: service occurs on the side that wins!
				/* ball ready for service */ b.p.x = BX; b.p.y = BY; b.v.x = 0.; b.v.y = 0.;
				b.v.x = Math.random() * 10 - 5; b.live = true;
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