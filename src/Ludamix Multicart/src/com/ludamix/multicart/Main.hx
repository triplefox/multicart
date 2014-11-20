package com.ludamix.multicart;

import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import openfl.events.KeyboardEvent;

/**
 * ...
 * @author nblah
 */

class Main extends Sprite 
{
	function init() 
	{
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
	
	public static function startGame(newgame : Dynamic)
	{
		if (game != null) game.exit(); game = newgame; game.start();
	}
	
}
