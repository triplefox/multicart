package com.ludamix.multicart;
import com.ludamix.multicart.d.InputConfig;
import com.ludamix.multicart.d.Proportion;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.Lib;

typedef MulticartCatalog = {
	name:String,
	desc:String,
	game:Void->Dynamic
};

class Menu implements MulticartGame
{
	
	public function new(){}
	
	public var surf : Bitmap;
	public var ts : Tileset;
	public var cat : Array<MulticartCatalog>;
	public var gameptr : Int;
	
	public function start(inp : InputConfig)
	{
		cat = [
			{name:"Spacewar!", desc:"1961 two-player space combat.", game:function(){ return new Spacewar();} },
			{name:"Digital Snowbody", desc:"For LD31. Turn the knobs to make your own snowman.", game:function(){ return new Snowbody();}},
			{name:"Higenbotham", desc:"1958 Tennis for Two game", game:function(){ return new Higenbotham();} }
		];
		surf = new Bitmap(new BitmapData(300, 192, false, 0));
		ts = new Tileset(Assets.getBitmapData("img/atascii.png"), 8, 8); /* Atari ATASCII set */
		Lib.current.addChild(surf);
		Lib.current.stage.addEventListener(MouseEvent.CLICK, onClick);
		render();
		Lib.current.stage.addEventListener(Event.ENTER_FRAME, render);
	}
	
	public function render(?event : Event)
	{
		{ /* reset the game ptr */
			gameptr = -1;			
		}
		{ /* proportion & center the display */
			var sw = Lib.current.stage.stageWidth; var sh = Lib.current.stage.stageHeight;
			var sc = Proportion.bestfit(surf.width/surf.scaleX, surf.height/surf.scaleY, sw, sh);
			if (sc > 1) sc = Math.floor(sc); /* clamp to integer scale factors */
			surf.scaleX = sc; surf.scaleY = sc;
			surf.x = sw / 2 - surf.width / 2; surf.y = sh / 2 - surf.height / 2;
		}
		{ /* draw to bitmap */
			var sb = surf.bitmapData;
			sb.fillRect(sb.rect, 0xFF888888);
			
			var y = ts.th;
			var mx = surf.mouseX; var my = surf.mouseY;
			for (e in cat) /*draw each title (and associated desc)*/
			{
				var en = ' '+e.name+' ';
				var sz = ts.tsz(en);
				var r = new Rectangle(ts.sx(sb.width / 2 - sz.w / 2), y, sz.w, sz.h);
				if (r.contains(mx, my))
				{
					gameptr = cat.indexOf(e);
					/*invert title*/
					ts.t(sb, en, r.x, r.y, '\n', 128);
					{ /*draw desc*/
						var lb = linebreak(e.desc, Std.int(sb.width / ts.tw) - 2).join('\n');
						var sz2 = ts.tsz(lb);
						var r2 = new Rectangle(ts.sx(sb.width / 2 - sz2.w / 2), sb.height-sz2.h-ts.th, sz2.w, sz2.h);
						ts.t(sb, lb, r2.x, r2.y);
					}
				}
				else /*ordinary display*/
					ts.t(sb, en, r.x, r.y);
				y += ts.th;
			}
			
		}
	}
	
	public function linebreak(s : String, cols : Int) {
		var lns = s.split('\n'); /* acknowledge prebroken lines */
		var r = new Array<String>();
		for (l in lns)
		{
			while (l.length > cols) {
				var sl = l.substr(0, cols);
				var bkidx = sl.lastIndexOf(' ');
				if (bkidx == -1) bkidx = cols;
				r.push(l.substr(0, bkidx));
				l = StringTools.trim(l.substr(bkidx));
			}
			if (l.length > 0) r.push(l);
		}
		return r;
	}
	
	public function exit()
	{
		Lib.current.stage.removeEventListener(MouseEvent.CLICK, onClick);
		Lib.current.stage.removeEventListener(Event.ENTER_FRAME, render);
		Lib.current.removeChild(surf);
		surf.bitmapData.dispose();
	}
	
	public function onClick(event : MouseEvent)
	{
		if (gameptr != -1) { Main.startGame(cat[gameptr].game()); }
	}
	
}

class Tileset
{
	
	public var rs /*rectangles*/ : Array<Rectangle>;
	public var bd /*source bitmap*/ : BitmapData;
	public var tw /*tile width*/ : Int;
	public var th /*tile height*/ : Int;
	public var sw /*set width*/ : Int;
	public var sh /*set height*/ : Int;
	public static var p : Point; /* temp data cache */
	
	public function new(bd : BitmapData, tw : Int, th : Int)
	{
		this.bd = bd; this.tw = tw; this.th = th; rs = new Array(); if (p == null) p = new Point();
		/* cache rectangles */
		sw = 0; sh = 0;
		var x = 0; var y = 0; 
		while (y + th <= bd.height) 
			{ sw = 0; while (x + tw <= bd.width) { rs.push(new Rectangle(x, y, tw, th)); x += tw; sw += 1; } 
		x = 0; y += th; sh += 1; }
	}
	
	/* blit rect of single index with offset 'o' */ public inline function b(dest : BitmapData, idx : Int, x : Float, y : Float, ?o=0)
	{
		p.x = x; p.y = y; dest.copyPixels(bd, rs[idx+o], p, null, null, true);		
	}
	
	/* blit text, obeying line break char "lbc" */ public inline function t(dest : BitmapData, s : String, x : Float, y : Float, ?lbc = '\n', ?o=0)
	{
		for (l in s.split(lbc)) { st(dest, l, x, y, o); y += th; }
	}
	
	/* simple blit text (directly from LUT, no breaks) */ public inline function st(dest : BitmapData, s : String, x : Float, y : Float, ?o=0)
	{
		for (i in 0...s.length) { b(dest, s.charCodeAt(i), x, y, o); x += tw; }
	}
	
	/* get text size */ public inline function tsz(s : String, ?lbc = '\n') {
		var rw = 0.; var rh = 0.; var sp = s.split(lbc); 
		rh = sp.length * th; for (i in sp) { if (i.length > rw) rw = i.length; } rw *= tw;
		return {w:rw,h:rh};
	}
	
	/* snap x and y to implied grid */
	public inline function sx(x : Float) { return Std.int(x / tw) * tw; }
	public inline function sy(y : Float) { return Std.int(y / th) * th; }
	
	/* blit all the tiles left-to-right, top-to-bottom */ public function test(o : BitmapData, ?x : Float=0., y : Float=0.)
	{
		for (j in 0...sh) {st(o, [for (i in 0...sw) String.fromCharCode(i+j*sw)].join(""), x, y + j * th);}
	}
	
}