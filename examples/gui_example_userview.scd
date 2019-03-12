//gui example with userview / pen graphics

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b| b.start});
var buffer= OpenBCIbuf(board);
var width= 640, height= 640;
var win, usr, x= 0;
~amp= 1000;  //boost
buffer.start;
win= Window("gui example userview", Rect(10, 100, width, height)).front;
usr= UserView(win, Rect(0, 0, width, height));
usr.animate= true;
usr.frameRate= 60;
usr.background= Color.black;
usr.clearOnRefresh= false;
usr.drawFunc= {
	var chanHeight= height/board.numChannels;
	Pen.smoothing_(false);
	buffer.readData.do{|data|
		Pen.fillColor= Color.grey(0, 0.667);  //alpha
		Pen.fillRect(Rect(x, 0, 1, height));
		Pen.fillColor= Color.white;
		data.do{|val, y|
			val= (val*~amp).linlin(-8388608, 8388607, 0, chanHeight);
			Pen.fillRect(Rect(x, val+(y*chanHeight), 1, 1));
		};
		x= x+1%width;
	};
};
CmdPeriod.doOnce({win.close});
~openbci= board;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
~openbci.setSampleRate(6);
~openbci.setSampleRate(3);
~openbci.test2AmpFast;
~amp= 500;
~amp= 1000;
~amp= 2000;
