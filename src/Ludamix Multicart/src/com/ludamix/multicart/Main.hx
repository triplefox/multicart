package com.ludamix.multicart;

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
		inp.kbutton(37,"left"); inp.kincv(37,"horiz", -0.1);
		inp.kbutton(39,"right"); inp.kincv(39,"horiz", 0.1);
		inp.kbutton(38,"up"); inp.kincv(38,"vert", -0.1);
		inp.kbutton(40,"down"); inp.kincv(40,"vert", 0.1);
		inp.kbutton(65,"p1b1"); // A
		inp.kbutton(76,"p2b1"); // L
		/* quit to menu on "escape" key */
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, function(k : KeyboardEvent) { 
			if (k.keyCode == 27) startGame(new Menu()); } );
		/* default game */
		startGame(new Higenbotham());
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
	
	public static function startGame(newgame : Dynamic)
	{
		if (game != null) game.exit(); inp.resetTuners(); game = newgame; game.start(inp);
	}
	
}
