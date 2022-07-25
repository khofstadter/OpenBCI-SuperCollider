//fft gui example with userview / pen graphics

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var f= DataFFT(board, 512, \hamming);  //fft size
var win, img, frameCounter= 0;
var width= 640, height= f.fftSize2+1;
~channel= 2;  //which channel to read
~maxuV= 200;
win= Window("fft gui example userview", Rect(100, 100, width, height)).front;
img= Image.color(width, f.fftSize2+1, Color.black).interpolation_(\fast);
win.drawFunc= {
	var data= board.buffer[~channel];
	if(~notchFilter.notNil, {
		data= ~notchFilter.filter(data);
	});
	if(~bandpassFilter.notNil, {
		data= ~bandpassFilter.filter(data);
	});

	f.fft(data).do{|val, y|
		var col= Color.grey(val.explin(0.1, ~maxuV, 0, 1));  //0.1-200 uV
		img.setColor(col, frameCounter%img.width, img.height-1-y);
	};
	Pen.drawImage(Rect(0, 0, win.bounds.width, win.bounds.height), img);
	frameCounter= frameCounter+1;
};
Routine({
	var nextTime;
	while({win.isClosed.not}, {
		nextTime= Main.elapsedTime+(1/60);
		win.refresh;
		(nextTime-Main.elapsedTime).max(0.001).wait;
	});
}).play(AppClock);
win.onClose= {img.free; board.stop};
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
~channel= 0;
~channel= 1;
~channel= 2;
~channel= 3;
~maxuV= 1000;
~maxuV= 10;
~openbci.setSampleRate(3)  //only when wifi shield connected
