//gui example with userview / pen graphics

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b| b.start});
var buffer= OpenBCIbuf(board, 100, true, false);
var width= 640, height= 640;
var win, usr, x= 0;
~maxuV= 200;
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
	Pen.translate(0, chanHeight*0.5);
	buffer.readData.do{|data|
		Pen.fillColor= Color.grey(0, 0.667);  //alpha
		Pen.fillRect(Rect(x, 0, 1, height));
		Pen.fillColor= Color.white;
		data.do{|val, y|
			Pen.fillRect(Rect(x, val/~maxuV+(y*chanHeight), 1, 1));
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
~openbci.test1AmpFast;
~openbci.test1AmpSlow;
~openbci.test2AmpFast;
~openbci.test2AmpSlow;
~openbci.testDC
~openbci.testGnd
~openbci.setDefaultChannelSettings
~maxuV= 10;  //-200 to 200uV
~maxuV= 200;  //-200 to 200uV
~maxuV= 1000;  //-1000 to 1000uV
~maxuV= 10000;  //-10000 to 10000uV
~br= DataFilterNotch('50');
~openbci.addFilter(~br);
~bp= DataFilterBandpass('5-50');
~openbci.addFilter(~bp);
~openbci.removeFilter(~br);
~openbci.removeFilter(~bp);
