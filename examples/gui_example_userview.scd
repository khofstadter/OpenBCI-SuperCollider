//gui example with userview / pen graphics

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
var width= 640, height= 640;
var win, usr, x= 0;
~maxuV= 20;
~notchFilter= DataFilterNotch('50');
~bandpassFilter= DataFilterBandpass('5-50');
win= Window("gui example userview", Rect(10, 100, width, height)).front;
usr= UserView(win, Rect(0, 0, width, height));
usr.animate= true;
usr.frameRate= 30;
usr.background= Color.black;
usr.clearOnRefresh= true;
usr.drawFunc= {
	var chanHeight= height/board.numChannels;
	Pen.smoothing_(false);
	Pen.fillColor= Color.white;
	Pen.translate(0, chanHeight*0.5);
	board.buffer.do{|data, y|
		if(~notchFilter.notNil, {
			data= ~notchFilter.filter(data);
		});
		if(~bandpassFilter.notNil, {
			data= ~bandpassFilter.filter(data);
		});
		data.reverse.do{|val, x|
			Pen.fillRect(Rect(width-x, val/~maxuV+(y*chanHeight), 1, 1));
		};
	};
};
CmdPeriod.doOnce({win.close});
~openbci= board;
)

~notchFilter= DataFilterNotch('50');
~notchFilter= DataFilterNotch('60');
~notchFilter= nil;
~bandpassFilter= DataFilterBandpass('1-50');
~bandpassFilter= DataFilterBandpass('5-50');
~bandpassFilter= DataFilterBandpass('15-50');
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

//to 'fix' the weird offset on the left hand side when using bandpass '1-50', increase the bufferSize
~openbci.bufferSize= 1200;  //around 2x display width is usually enough
