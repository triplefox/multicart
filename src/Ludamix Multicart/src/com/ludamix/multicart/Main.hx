package com.ludamix.multicart;

import com.ludamix.multicart.d.Beeper;
import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import openfl.events.KeyboardEvent;
import com.ludamix.multicart.d.InputConfig;

/**
 * ...
 * @author nblah
 */

class Main extends Sprite 
{
	function init() 
	{
		/* set up devices */
		inp = new InputConfig(); 
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, inp.onKeyDown);
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, inp.onKeyUp);
		/* p0: WASD */
		inp.kbutton(65,"p0left"); inp.kincv(65,"p0horiz", -0.1);
		inp.kbutton(68,"p0right"); inp.kincv(68,"p0horiz", 0.1);
		inp.kbutton(87,"p0up"); inp.kincv(87,"p0vert", -0.1);
		inp.kbutton(83,"p0down"); inp.kincv(83,"p0vert", 0.1);
		inp.kbutton(70,"p0b1"); // F
		inp.kbutton(71,"p0b2"); // G
		/* p1: arrows */
		inp.kbutton(37,"p1left"); inp.kincv(37,"p1horiz", -0.1);
		inp.kbutton(39,"p1right"); inp.kincv(39,"p1horiz", 0.1);
		inp.kbutton(38,"p1up"); inp.kincv(38,"p1vert", -0.1);
		inp.kbutton(40,"p1down"); inp.kincv(40,"p1vert", 0.1);
		inp.kbutton(186,"p1b1"); // ;
		inp.kbutton(222,"p1b2"); // '
		/* quit to menu on "escape" key */
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, function(k : KeyboardEvent) { 
			if (k.keyCode == 27) startGame(new Menu()); } );
		/* audio */
		beeper = new Beeper();
		/* default game */
		startGame(new Spacewar());
	}

	public function new() { 
		super(); 
		#if ios
		haxe.Timer.delay(init, 100); // iOS 6
		#else
		init();
		#end
	}
	
	public static function main() 
	{
		// static entry point
		Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		Lib.current.addChild(new Main());
	}
	
	public static var game:Dynamic;
	public static var inp:InputConfig;
	public static var beeper:Beeper;
	
	public static function startGame(newgame : Dynamic)
	{
		if (game != null) {game.exit();} inp.resetTuners(); game = newgame; game.start(inp);
	}
	
}
