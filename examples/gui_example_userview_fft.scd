//fft gui example with userview / pen graphics

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var fft= DataFFT(board, 512);  //fft size
var win, img, frameCounter= 0;
var width= 640, height= fft.fftSize2+1;
var channelData= [];
var notchFilter, bandpassFilter;
~channel= 2;  //which channel to read
~maxuV= 100;
~makeNotchFilter= {|type|
	if(DataFilterNotch.keys.includes(type).not, {
		notchFilter= nil;
	}, {
		notchFilter= DataFilterNotch(
			type,
			board.currentSampleRate,
			board.bufferSize
		);
	});
};
~makeNotchFilter.value('50');
~makeBandpassFilter= {|type|
	if(DataFilterBandpass.keys.includes(type).not, {
		bandpassFilter= nil;
	}, {
		bandpassFilter= DataFilterBandpass(
			type,
			board.currentSampleRate,
			board.bufferSize
		);
	});
};
~makeBandpassFilter.value('5-50');
win= Window("fft gui example userview", Rect(100, 100, width, height)).front;
img= Image.color(width, fft.fftSize2+1, Color.black).interpolation_(\fast);
win.drawFunc= {
	channelData= fft.fft(channelData);
	if(~smoothingFilter.notNil, {
		channelData= ~smoothingFilter.filterLog(channelData.max(0.01));
	});
	channelData.do{|val, y|
		var col= Color.grey(val.explin(0.1, ~maxuV, 0, 1));  //0.1-100 uV
		img.setColor(col, frameCounter%img.width, (img.height-1-y).clip(0, img.height-1));
	};
	Pen.drawImage(Rect(0, 0, win.bounds.width, win.bounds.height), img);
	frameCounter= frameCounter+1;
};
win.onClose= {img.free; board.stop};
CmdPeriod.doOnce({win.close});

board.dataAction= {|num, data, acc|
	channelData= board.buffer[~channel];
	if(notchFilter.notNil, {
		channelData= notchFilter.filterN(channelData.last);
	});
	if(bandpassFilter.notNil, {
		channelData= bandpassFilter.filterN(channelData.last);
	});
};

Routine({
	var nextTime;
	while({win.isClosed.not}, {
		nextTime= Main.elapsedTime+(1/60);
		win.refresh;
		(nextTime-Main.elapsedTime).max(0.001).wait;
	});
}).play(AppClock);

~openbci= board;
)

~makeNotchFilter.value('50');
~makeNotchFilter.value('60');
~makeNotchFilter.value(nil);
~makeBandpassFilter.value('1-50');
~makeBandpassFilter.value('5-50');
~makeBandpassFilter.value('15-50');
~makeBandpassFilter.value('7-13');
~makeBandpassFilter.value(nil);
~smoothingFilter= DataSmoothing(0.9);
~smoothingFilter= nil;

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
