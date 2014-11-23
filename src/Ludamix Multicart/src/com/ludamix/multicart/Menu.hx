package com.ludamix.multicart;
import com.ludamix.multicart.d.InputConfig;

class Menu implements MulticartGame
{
	
	public function new(){}
	
	public function start(inp : InputConfig)
	{
		trace("start");
	}
	
	public function exit()
	{
		trace("exit");
	}
	
}