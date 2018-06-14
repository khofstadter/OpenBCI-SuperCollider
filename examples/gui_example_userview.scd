//gui example with userview / pen graphics
(
var width= 640, height= 480;
var win, usr;
win= Window("gui example userview", Rect(100, 100, width, height)).front;
usr= UserView(win, Rect(0, 0, width, height));
usr.animate= true;
usr.frameRate= 60;
usr.background= Color.black;
usr.clearOnRefresh= false;
usr.drawFunc= {
	var x= usr.frame%width;
	var chanHeight;
	Pen.smoothing_(false);
	Pen.fillColor= Color.grey(0, 0.5);  //alpha
	Pen.fillRect(Rect(x, 0, 1, height));
	if(~openbci.data.notNil, {
		chanHeight= height/~openbci.data.size;
		Pen.fillColor= Color.white;
		~openbci.data.do{|val, y|
			Pen.fillRect(Rect(x, val.linlin(-8388607, 8388607, 0, chanHeight)+(y*chanHeight), 1, 1));
		};
	});
};
~openbci= Cyton("/dev/tty.OpenBCI-DM00DRM0", initAction:{~openbci.start});  //edit
CmdPeriod.doOnce({win.close});
)

~openbci.softReset;
~openbci.start;