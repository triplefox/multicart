package com.ludamix.multicart.d;
class Proportion
{
	public static inline function bestfit(w0, h0, w1, h1)
	/* find the best scale for a rectangle of width w0, h0 trying to fit in w1, h1*/
	{
		var sc0 = (w0 > h0) ? h0 : w0;
		var sc1 = (w1 > h1) ? h1 : w1;
		return (sc0 > sc1) ? sc0/sc1 : sc1/sc0;		
	}	
}