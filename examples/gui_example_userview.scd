//gui example with userview / pen graphics

(
//var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match you board
var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
var width= 640, height= 640;
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
	if(board.data.notNil, {
		chanHeight= height/board.data.size;
		Pen.fillColor= Color.white;
		board.data.do{|val, y|
			Pen.fillRect(Rect(x, val.linlin(-8388608, 8388607, 0, chanHeight)+(y*chanHeight), 1, 1));
		};
	});
};
CmdPeriod.doOnce({win.close});
~openbci= board;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
