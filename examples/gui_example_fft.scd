//fft gui example with multisliders

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var fft= DataFFT(board, 256);
var win, msliders;
var notchFilters, bandpassFilters, smoothingFilters;
var channels= {|i|
	(
		data: []
	)
}.dup(board.numChannels);
~makeNotchFilters= {|type|
	if(DataFilterNotch.keys.includes(type).not, {
		notchFilters= nil;
	}, {
		notchFilters= {
			DataFilterNotch(
				type,
				board.currentSampleRate,
				board.bufferSize
			);
		}.dup(board.numChannels);
	});
};
~makeNotchFilters.value('50');
~makeBandpassFilters= {|type|
	if(DataFilterBandpass.keys.includes(type).not, {
		bandpassFilters= nil;
	}, {
		bandpassFilters= {
			DataFilterBandpass(
				type,
				board.currentSampleRate,
				board.bufferSize
			);
		}.dup(board.numChannels);
	});
};
~makeBandpassFilters.value('5-50');
~makeSmoothingFilters= {|factor|
	smoothingFilters= {DataSmoothing(factor)}.dup(board.numChannels);
};
win= Window("fft gui example multislider", Rect(100, 100, 640, 640)).front;
msliders= {
	MultiSliderView()
	.canFocus_(false)
	.isFilled_(true)
	.colors_(Color.black, Color.grey)
	.value_([0])
	.elasticMode_(1);
}.dup(board.numChannels);
win.layout= VLayout(*msliders);
CmdPeriod.doOnce({win.close});

board.dataAction= {|num, data, acc|
	channels.do{|c, i|
		c.data= board.buffer[i];
		if(notchFilters.notNil, {
			c.data= notchFilters[i].filterN(c.data.last);
		});
		if(bandpassFilters.notNil, {
			c.data= bandpassFilters[i].filterN(c.data.last);
		});
	};
};

Routine({
	var nextTime;
	while({win.isClosed.not}, {
		nextTime= Main.elapsedTime+(1/40);  //framerate
		channels.do{|c, i|
			if(c.data.size>=fft.fftSize, {
				c.data= fft.fft(c.data);
				if(smoothingFilters.notNil, {
					c.data= smoothingFilters[i].filter(c.data.max(0.01));
				});
				msliders[i].value= c.data.explin(0.1, 100, 0, 1);  //0.1-100 uV
			});
		};
		(nextTime-Main.elapsedTime).max(0.001).wait;
	});
}).play(AppClock);

~openbci= board;
)

~makeNotchFilters.value('50');
~makeNotchFilters.value('60');
~makeNotchFilters.value(nil);
~makeBandpassFilters.value('1-50');
~makeBandpassFilters.value('5-50');
~makeBandpassFilters.value('15-50');
~makeBandpassFilters.value('7-13');
~makeBandpassFilters.value(nil);
~makeSmoothingFilters.value(0.9);
~makeSmoothingFilters.value(0);

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
