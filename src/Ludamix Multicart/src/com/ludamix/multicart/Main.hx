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
	var inited:Bool;
	
	/* ENTRY POINT */
	
	function resize(e) 
	{
		if (!inited) init();
		// else (resize or orientation change)
	}
	
	function init() 
	{
		if (inited) return;
		inited = true;

		stage.addEventListener(KeyboardEvent.KEY_DOWN, function(k : KeyboardEvent) { // quit to menu on "escape" key
			if (k.keyCode == 27) startGame(new Menu()); } );
		startGame(new Menu());
	}

	/* SETUP */

	public function new() 
	{
		super();	
		addEventListener(Event.ADDED_TO_STAGE, added);
	}

	function added(e) 
	{
		removeEventListener(Event.ADDED_TO_STAGE, added);
		stage.addEventListener(Event.RESIZE, resize);
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
