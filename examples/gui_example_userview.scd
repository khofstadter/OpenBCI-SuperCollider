//gui example with userview / pen graphics

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var width= 640, height= 640;
var win, img;
var channels= {
	(
		data: []
	)
}.dup(board.numChannels);
var notchFilters, bandpassFilters;
~maxuV= 20;
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
width= width.min(board.bufferSize);
win= Window("gui example userview", Rect(10, 100, width, height)).front;
img= Image.color(width, height, Color.black).interpolation_(\fast);
win.drawFunc= {
	var chanHeight= height/board.numChannels;
	var color= Color.white;
	img.fill(Color.black);
	channels.do{|c, i|
		if(c.data.size>0, {
			width.do{|x|
				var val= c.data[c.data.size-1-x];
				var y= (val/~maxuV+(i+0.5*chanHeight)).asInteger;
				img.setColor(color, width-1-x, y.clip(0, img.height-1));
			};
		});
	};
	Pen.drawImage(Rect(0, 0, win.bounds.width, win.bounds.height), img);
};
win.onClose= {img.free; board.stop};
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
		nextTime= Main.elapsedTime+(1/60);
		win.refresh;
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
~maxuV= 10;  //-10 to 10uV
~maxuV= 20;  //-20 to 20uV (default)
~maxuV= 200;  //-200 to 200uV
~maxuV= 1000;  //-1000 to 1000uV
~maxuV= 10000;  //-10000 to 10000uV

//to 'fix' the weird offset on the left hand side when using bandpass '1-50', increase the bufferSize
~openbci.bufferSize= 1200;  //around 2x display width is usually enough
