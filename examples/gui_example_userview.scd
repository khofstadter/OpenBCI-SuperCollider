//gui example with userview / pen graphics

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var width= 640, height= 640;
var win, img;
width= width.min(board.bufferSize);
~maxuV= 20;
~notchFilter= DataFilterNotch('50');
~bandpassFilter= DataFilterBandpass('5-50');
win= Window("gui example userview", Rect(10, 100, width, height)).front;
img= Image.color(width, height, Color.black).interpolation_(\fast);
win.drawFunc= {
	var chanHeight= height/board.numChannels;
	var color= Color.white;
	img.fill(Color.black);
	board.buffer.do{|data, i|
		if(~notchFilter.notNil, {
			data= ~notchFilter.filter(data);
		});
		if(~bandpassFilter.notNil, {
			data= ~bandpassFilter.filter(data);
		});
		width.do{|x|
			var val= data[data.size-1-x];
			var y= (val/~maxuV+(i+0.5*chanHeight)).asInteger;
			img.setColor(color, width-1-x, y);
		};
		Pen.drawImage(Rect(0, 0, win.bounds.width, win.bounds.height), img);
	};
};
win.onClose= {img.free; board.stop};
Routine({while({win.isClosed.not}, {win.refresh; (1/30).wait})}).play(AppClock);
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
