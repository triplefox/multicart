package com.ludamix.multicart;
import com.ludamix.multicart.d.Beeper;
import com.ludamix.multicart.d.InputConfig;
import com.ludamix.multicart.d.Proportion;
import com.ludamix.multicart.d.RangeMapping;
import com.ludamix.multicart.d.T;
import haxe.ds.Vector;
import openfl.geom.Point;
import openfl.geom.Matrix;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
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

typedef Particle = { v /*velocity*/ :Vec2F, p /*position*/ :Vec2F, x0 /*extrusions*/ :Point, x1:Point, a /*angle*/ : Float, 
		av /*angle velocity*/ : Float, l /*lifetime*/ : Int };

class Spacewar implements MulticartGame
{
	
	public function new(){}
	
	public var inp /* input config and state */ : InputConfig;
	public var disp /* main display */ : Sprite;
	public var pfs /* playfield sprite */ : Sprite;
	public var players : Array<{ v /*velocity*/ :Vec2F, p /*position*/ :Vec2F, a /*angle*/ : Float, av /*angle velocity*/ : Float, o /*owner*/ : Int, l /*alive*/ : Bool}>;
	public var projectiles : Array<{ v /*velocity*/ :Vec2F, p /*position*/ :Vec2F, l /*alive*/ : Bool, o /*owner*/ : Int}>;
	public var controls : Array<{ f /*fire*/ :Bool, t /*thrust*/ :Bool, l /*left*/ :Bool, r /*right*/ :Bool, h /*hyperspace*/ :Bool }>;	
	public var beep_gain : Array<Vector<Float>>; /* beeper gain */
	public var beep_freq : Array<Vector<Float>>; /* beeper freq */
	public var plsprbase : Array<Array<Array<Array<Float>>>>; /* player sprite source data */
	public var particles : Array <Particle>;
	public static inline var PW /* playfield width */ = 200;
	public static inline var PH /* playfield height */ = 200;
	public static inline var PSCALE /* player scale */ = 10;
	public static inline var GRAVITY /* added to players each frame towards center of playfield(sun) */ = 0.1;
	public static inline var P0X /* player 0 init x */ = PW * 0.2;
	public static inline var P0Y /* player 0 init y */ = PH * 0.2;
	public static inline var P0A /* player 0 init angle */ = T.deg2rad(45);
	public static inline var P1X /* player 1 init x */ = PW * 0.8;
	public static inline var P1Y /* player 1 init y */ = PH * 0.8;
	public static inline var P1A /* player 1 init angle */ = T.deg2rad(-135);
	public static inline var OOB /* out of bounds range */ = 200.;
	
	public static inline var PCOLLISION /* player collision circle */ = PSCALE * 0.9;
	
	public static inline var ROTAC /* rotation acceleration */ = 0.01;
	public static inline var ROTF /* rotation friction */ = 0.8;
	public static inline var THRUSTM /* thrust magnitude */ = 0.01;
	public static inline var SHOOTM /* shoot magnitude */ = 4.;
	
	public static inline var EXPLODEF /* explosion frames */ = 120;
	
	public function start(inp : InputConfig)
	{
		{ /* init display */ disp = new Sprite(); Lib.current.stage.addChild(disp); }
		{ /* init playfield */ pfs = new Sprite(); disp.addChild(pfs); }
		resetRound();
		{ /* init player sprites - stored as runs of connected segments with the tip of the nose at 1,0 */
			plsprbase = [
				/*p0*/
				[[[1., 0.], [ -0.9, -0.8], [ -0.9, 0.8], [ 1., 0.]], [[ -0.9, -0.5], [ -1.0, -0.5], [ -1.0, 0.5], [ -0.9, 0.5]]],
				/*p1*/
				[[[-1., 0.4], [-0.9,0.0], [ -1., -0.4], [ -0.5, -0.8],
					[-0.4, -0.8], [0.1, -0.3], [1.0,-0.1], [1.0,0.1], [0.1,0.3], [ -0.5, 0.8], [ -1., 0.4]]]
			];
		}
		{ /* configure input */ this.inp = inp;
			controls = [for (i in 0...2) { f:false, t:false, l:false, r:false, h:false } ];
			for (i in 0...2) {
				inp.tbool(controls[i], "t", false, 'p${i}uphold', 'Player ${i} Thrust');
				inp.tbool(controls[i], "l", false, 'p${i}lefthold', 'Player ${i} Left');
				inp.tbool(controls[i], "r", false, 'p${i}righthold', 'Player ${i} Right');
				inp.tbool(controls[i], "f", false, 'p${i}b0tap', 'Player ${i} Fire');
				inp.tbool(controls[i], "h", false, 'p${i}b1tap', 'Player ${i} Hyperspace');
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
		{ /* init projectiles */ projectiles = [for (i in 0...100) {v:Vec2F.c(0.,0.), p:Vec2F.c(0.,0.), l:false, o:-1}]; }
		{ /* init particles */ particles = []; }
		{ /* init players */ players = [ { v:Vec2F.c(0., 0.), p:Vec2F.c(P0X, P0Y), a:P0A, av:0., o:0, l:true },
										 { v:Vec2F.c(0., 0.), p:Vec2F.c(P1X, P1Y), a:P1A, av:0., o:1, l:true } ]; }		
	}
	
	public function shootSound(idx : Int) { Main.beeper.qg = [beep_gain[0]]; Main.beeper.qf = [beep_freq[idx]]; }
	public function hitSound() { Main.beeper.qg = [beep_gain[1],beep_gain[2]]; Main.beeper.qf = [beep_freq[2],beep_freq[3]]; }
	
	public function oob(v : Vec2F, z : Float) /*(-z,z+PW],(-z,z+PH]*/ { return v.x < -z || v.y < -z || v.x >= z+PW || v.y >= z+PH; }
	
	public function frame(ev : Event)
	{
		{ /* update inputs and refresh tuning */ inp.poll();
		}
		{ /* simulate */
			for (i in 0...controls.length)
			{
				var p = players[i];
				if (p.l)
				{
					/* player rotations */
					if (controls[i].l) { p.av -= ROTAC; }
					if (controls[i].r) { p.av += ROTAC; }
					/* add angular velocity and friction */ p.a += p.av; p.av *= ROTF;
					if (controls[i].t) { var tv /*thrust vec*/ = new Vec2F(); tv.ofRadmul(p.a, THRUSTM); p.v.addf(tv); }
					if (controls[i].f) { 
						shootSound(p.o);
						for (j in projectiles) { if (!j.l) { 
							j.l = true; j.o = p.o; j.p.setf(p.p); j.v.setf(p.v);
							var sv /*shoot vec*/ = new Vec2F(); sv.ofRadmul(p.a, SHOOTM); j.v.addf(sv); 
							sv.ofRadmul(p.a, PSCALE); j.p.addf(sv);
							break; }}
					}
					if (controls[i].h) {
					}
				}
				controls[i].f = false;
				controls[i].h = false;
				/* add positional velocity */ p.p.addf(p.v);
			}
			/* update projectiles (we just turn them off instead of despawning) */
			var c = 0;  for (p in projectiles) { if (p.l) { c += 1;  p.p.addf(p.v); if (oob(p.p, OOB)) p.l = false; } }
			/* update particles (count backwards to despawn cleanly) */
			{ var i = particles.length - 1; while (i >= 0) { var p = particles[i]; p.l -= 1;
				p.a += p.av; p.p.addf(p.v);
				/*despawn*/ if (p.l <= 0) { particles.splice(i, 1); } i -= 1; } }
			/* collide */
			{
				for (j in projectiles)
				{
					if (j.l)
					{
						for (l in players)
						{
							if (j.o != l.o && l.l)
							{
								if (Vec2F.distSqr(j.p, l.p) < PCOLLISION * PCOLLISION)
								{
									l.l = false;
									hitSound();
									for (shp in plsprbase[l.o])
									{
										/* spawn explosion particles - we take the original gfx and make each segment a particle */ 
										for(z in 0...shp.length-1) { 
											var i = shp[z]; var j = shp[z + 1];
											var rndv = Vec2F.c((Math.random() - 0.5) * 2, (Math.random() - 0.5) * 2);
											rndv.addf(l.v);
											var rndav = (Math.random() - 0.5)*0.1 + l.av;
											/* spawn the segment */ particles.push({ v:rndv, p:l.p.clone(), 
												x0:new Point(i[0], i[1]), x1:new Point(j[0], j[1]),
												a:l.a, av:rndav, l:EXPLODEF } );
										}
									}									
								}
							}
						}
					}
				}
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
			{ /* draw the playfield (per-frame vector graphics) */
				var g = pfs.graphics; g.clear();
				g.lineStyle(2., 0xFFFFFFFF, 1.);
				for (p in projectiles) { if (p.l) { g.moveTo(p.p.x, p.p.y); g.lineTo(p.p.x - p.v.x, p.p.y - p.v.y); } }
				g.lineStyle(2. / PSCALE, 0xFFFFFFFF, 1.);
				for (p in particles) { 
					var m = new Matrix(); m.scale(PSCALE, PSCALE); m.rotate(p.a);
					var p0 = m.deltaTransformPoint(p.x0);
					var p1 = m.deltaTransformPoint(p.x1);
					g.moveTo(p.p.x + p0.x, p.p.y + p0.y); g.lineTo(p.p.x + p1.x, p.p.y + p1.y); }
				for (p in players) { if (p.l) { 
						var m = new Matrix(); m.scale(PSCALE, PSCALE); m.rotate(p.a);
						var spr = plsprbase[p.o];
						for (v in spr)
						{
							for (i in 0...(v.length-1))
							{
								var v0 = v[i]; var v1 = v[i+1];
								var p0 = m.deltaTransformPoint(new Point(v0[0], v0[1]));
								var p1 = m.deltaTransformPoint(new Point(v1[0], v1[1]));
								g.moveTo(p.p.x + p0.x, p.p.y + p0.y); g.lineTo(p.p.x + p1.x, p.p.y + p1.y); 
							}
						}
					}
				}				
			}
		}
		{ /* update game state */
			var livecount = 0;
			for (p in players)
			{
				if (p.l) livecount++;
			}
			/* dead? */
			if (livecount <= 1 && particles.length <= 0)
			{
				resetRound();
			}
			/* out of bounds? */
			{
				for (p in players) {
					if (oob(p.p, OOB)) {
						resetRound();
					}
				}
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