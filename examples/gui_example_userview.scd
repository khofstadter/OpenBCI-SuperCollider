//gui example with userview / pen graphics

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b| b.start});
var width= 640, height= 640;
var win, usr, x= 0;
~maxuV= 20;
win= Window("gui example userview", Rect(10, 100, width, height)).front;
usr= UserView(win, Rect(0, 0, width, height));
usr.animate= true;
usr.frameRate= 30;
usr.background= Color.black;
usr.clearOnRefresh= true;
usr.drawFunc= {
	var chanHeight= height/board.numChannels;
	var buffer= board.buffer.deepCopy;
	if(~notchFilter.notNil, {
		buffer= ~notchFilter.filter(buffer, 5750-width-500, 5750);
	});
	if(~bandpassFilter.notNil, {
		buffer= ~bandpassFilter.filter(buffer, 5750-width-500, 5750);
	});
	Pen.smoothing_(false);
	Pen.fillColor= Color.white;
	Pen.translate(0, chanHeight*0.5);
	buffer.do{|buf, y|
		width.do{|x|
			var val= buf[buf.size-1-x];
			Pen.fillRect(Rect(x, val/~maxuV+(y*chanHeight), 1, 1));
		};
	};
};
CmdPeriod.doOnce({win.close});
~openbci= board;
)

~notchFilter= DataFilterNotch('50');
~notchFilter= nil;
~bandpassFilter= DataFilterBandpass('5-50');
~bandpassFilter= DataFilterBandpass('7-13');
~bandpassFilter= nil;


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
