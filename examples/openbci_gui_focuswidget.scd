//port of OpenBCI_GUI focus widget, remake in supercollider by f.olofsson 2019
//MIT License, Copyright (c) 2018 OpenBCI, https://github.com/OpenBCI/OpenBCI_GUI/blob/master/LICENSE

//TODO test with ganglion and daisy

(
var activeChannels= #[0, 1, 2, 3, 4, 5, 6, 7];
var bands= #[
	["alpha", 7.5, 12.5, 0.7, 2.0],  //name, low freq, high freq, thresh, max value
	["beta", 12.5, 30.0, 0.7, 2.0]
];
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var notchFilters, bandpassFilters, smoothingFilters;
var fft= DataFFT(board, 256);
var fps= 60;
var usr, pop1, pop2, btn1, btn2, pw, po;
var backgroundColor, unfocusedColor, focusedColor;
var f0= Font("Helvetiva", 16);
var f1= Font("Helvetiva", 12);
var f2= Font("Helvetiva", 10);
var colors= [
	Color.new255(255, 218, 24),  //yellow cursor
	Color.new255(35, 81, 151),
	Color.new255(59, 122, 211),
	Color.new255(170, 218, 79),  //green
	Color.new255(40, 99, 186),
	Color.new255(75, 136, 222),
	Color.new255(252, 199, 53),  //orange
	Color.new255(40, 99, 186),
	Color.new255(75, 136, 222),
	Color.new255(126, 243, 252)  //cyan
];
var channels= {|i|
	(
		color: colors.wrapAt(i),
		active: activeChannels.includes(i),
		data: []
	)
}.dup(board.numChannels);

//--window
var win= Window("focus widget", Rect(10, 100, 512, 320));
win.view.minSize= Size(410, 220);
win.background= Color.white;
win.drawFunc= {
	Pen.color= Color.black;
	Pen.stringAtPoint("Focus Widget", Point(10, 10), f0);
};
win.front;
CmdPeriod.doOnce({win.close});

//--plot
usr= UserView(win, Rect(*#[0.05, 0.19, 0.9, 0.76]*win.bounds.extent.asArray));
usr.background= Color.new255(245, 245, 245, 220);
usr.clearOnRefresh= true;
usr.drawFunc= {
	var data;
	var ub= usr.bounds;
	var rad= ub.width*0.1375;
	var tri= ub.width*0.01;
	var str, focused, alphaY, betaY;
	var w1= 0, w2= ub.width*0.255;
	var h1= 0, h3= ub.height*0.8;
	var h2a= h3-(bands[0][3]/bands[0][4]*h3);
	var h2b= h3-(bands[1][3]/bands[1][4]*h3);
	var indices= bands.collect{|b| [fft.freqToIndex(b[1]), fft.freqToIndex(b[2])]};
	var factor= fft.fftSize/board.currentSampleRate;
	var alpha, beta;
	var bandsData= {[]}.dup(bands.size);
	channels.do{|c, i|
		if(c.active and:{c.data.size>0}, {
			c.data= fft.fft(c.data);
			if(pop2.value>0, {
				c.data= smoothingFilters[i].filterLog(c.data.max(0.01));
			});
			bands.do{|b, j|
				var arr= c.data.copyRange(indices[j][0], indices[j][1]-1)**2*factor/4;
				bandsData[j]= bandsData[j]++arr;
			};
		});
	};
	alpha= bandsData[0].sqrt.mean;
	beta= bandsData[1].sqrt.mean;
	focused= alpha>bands[0][3] and:{beta<bands[1][3]};

	Pen.push;
	Pen.translate(ub.width*0.23, ub.height*0.5);
	if(focused, {
		Pen.fillColor= focusedColor;
	}, {
		Pen.fillColor= backgroundColor;
	});
	Pen.fillOval(Rect.aboutPoint(Point(0, 0), rad, rad));
	if(focused, {
		Pen.fillColor= focusedColor;
		str= "focused!";
	}, {
		Pen.fillColor= unfocusedColor;
		str= "not focused";
	});
	Pen.stringAtPoint(str, Point(0-str.bounds(f1).width/2, ub.height*0.35), f1);
	Pen.pop;

	alphaY= h3-(h3-h1*(alpha/bands[0][4]).clip(0, 1));
	betaY= h3-(h3-h1*(beta/bands[1][4]).clip(0, 1));
	Pen.push;
	Pen.translate(ub.width*0.575, ub.height*0.1);
	Pen.strokeColor= unfocusedColor;
	Pen.width= 1;
	Pen.moveTo(Point(-10+w1, h1));
	Pen.lineTo(Point(ub.width*0.1+w1, h1));
	Pen.moveTo(Point(-10+w2, h1));
	Pen.lineTo(Point(ub.width*0.1+w2, h1));
	Pen.moveTo(Point(-10+w1, h2a));
	Pen.lineTo(Point(ub.width*0.1+w1, h2a));
	Pen.moveTo(Point(-10+w2, h2b));
	Pen.lineTo(Point(ub.width*0.1+w2, h2b));
	Pen.moveTo(Point(-10+w1, h3));
	Pen.lineTo(Point(ub.width*0.1+w1, h3));
	Pen.moveTo(Point(-10+w2, h3));
	Pen.lineTo(Point(ub.width*0.1+w2, h3));
	Pen.moveTo(Point(ub.width*0.1+w1, h1+10));
	Pen.lineTo(Point(ub.width*0.1+w1, h2a-10));
	Pen.moveTo(Point(ub.width*0.1+w2, h2b+10));
	Pen.lineTo(Point(ub.width*0.1+w2, h3));
	Pen.stroke;

	if(focused, {
		Pen.fillColor= focusedColor;
	}, {
		Pen.fillColor= unfocusedColor;
	});
	Pen.stringAtPoint(bands[0][0], Point(w1, ub.height*0.81), f1);
	Pen.stringAtPoint(bands[1][0], Point(w2, ub.height*0.81), f1);
	Pen.fillColor= backgroundColor;
	Pen.fillRect(Rect(w1, h2a, ub.width*0.08, h3-h2a));
	Pen.fillRect(Rect(w2, 0, ub.width*0.08, h2b));
	if(alpha>bands[0][3] and:{alpha<bands[0][4]}, {
		Pen.fillColor= focusedColor;
	}, {
		Pen.fillColor= unfocusedColor;
	});
	Pen.fillRect(Rect(w1, 0, ub.width*0.08, h2a));
	if(beta<bands[1][3], {
		Pen.fillColor= focusedColor;
	}, {
		Pen.fillColor= unfocusedColor;
	});
	Pen.fillRect(Rect(w2, h2b, ub.width*0.08, h3-h2b));

	Pen.strokeColor= colors[0];
	Pen.width= 4;
	Pen.moveTo(Point(-10+w1, alphaY));
	Pen.lineTo(Point(ub.width*0.1+w1, alphaY));
	Pen.moveTo(Point(-10+w2, betaY));
	Pen.lineTo(Point(ub.width*0.1+w2, betaY));
	Pen.stroke;

	Pen.fillColor= Color.grey(0.757);
	Pen.moveTo(Point(ub.width*0.1+w1-tri, h1));
	Pen.lineTo(Point(ub.width*0.1+w1+tri, h1-tri));
	Pen.lineTo(Point(ub.width*0.1+w1+tri, h1+tri));
	Pen.moveTo(Point(ub.width*0.1+w1-tri, h2a));
	Pen.lineTo(Point(ub.width*0.1+w1+tri, h2a-tri));
	Pen.lineTo(Point(ub.width*0.1+w1+tri, h2a+tri));
	Pen.moveTo(Point(ub.width*0.1+w2-tri, h2b));
	Pen.lineTo(Point(ub.width*0.1+w2+tri, h2b-tri));
	Pen.lineTo(Point(ub.width*0.1+w2+tri, h2b+tri));
	Pen.fill;

	Pen.translate(0, -6);
	Pen.fillColor= unfocusedColor;
	Pen.stringAtPoint(bands[0][4].asString, Point(w1-33, h1), f2);
	Pen.stringAtPoint(bands[1][4].asString, Point(w2-33, h1), f2);
	Pen.stringAtPoint(bands[0][3].asString, Point(w1-33, h2a), f2);
	Pen.stringAtPoint(bands[1][3].asString, Point(w2-33, h2b), f2);
	Pen.stringAtPoint("0.0", Point(w1-33, h3), f2);
	Pen.stringAtPoint("0.0", Point(w2-33, h3), f2);
	Pen.pop;
};
usr.resize= 5;
usr.canFocus= false;

//--menus
pw= win.bounds.width*0.125;
po= win.bounds.width-((pw+2)*3.5);
StaticText(win, Rect(po, 1, pw, 20)).align_(\center).string_("Theme");
StaticText(win, Rect((pw+2)+po, 1, pw, 20)).align_(\center).string_("Smooth");
StaticText(win, Rect((pw+2)*2+po, 1, pw, 20)).align_(\center).string_("Filters");
pop1= PopUpMenu(win, Rect(po, 20, pw, 20))
.items_(#["Green", "Orange", "Cyan"])
.action_{|v|
	backgroundColor= colors[v.value*3+1];
	unfocusedColor= colors[v.value*3+2];
	focusedColor= colors[v.value*3+3];
}.valueAction_(0);
pop2= PopUpMenu(win, Rect((pw+2)+po, 20, pw, 20))
.items_(#["0.0", "0.5", "0.75", "0.9", "0.95", "0.98"])
.action_{|v|
	smoothingFilters= {DataSmoothing(v.item.asFloat)}.dup(board.numChannels);
}.valueAction_(3);
btn1= Button(win, Rect((pw+2)*2+po, 20, pw/2, 20)).states_(
	[["Off"]]++DataFilterNotch.keys.collect{|x| [x.asString+"Hz"]}
).action_{|v|
	if(v.value>0, {
		notchFilters= {
			DataFilterNotch(
				DataFilterNotch.keys[v.value-1],
				board.currentSampleRate,
				board.bufferSize
			);
		}.dup(board.numChannels);
	}, {
		notchFilters= nil;
	});
}.valueAction_(1);
btn2= Button(win, Rect((pw+2)*2.5+po, 20, pw/2, 20)).states_(
	[["Off"]]++DataFilterBandpass.keys.collect{|x| [x.asString]}
).action_{|v|
	if(v.value>0, {
		bandpassFilters= {
			DataFilterBandpass(
				DataFilterBandpass.keys[v.value-1],
				board.currentSampleRate,
				board.bufferSize
			);
		}.dup(board.numChannels);
	}, {
		bandpassFilters= nil;
	});
}.valueAction_(1);
win.view.children.reject{|v| v==usr}.do{|v| v.resize_(3).font_(f2)};

board.dataAction= {|num, data, acc|
	channels.do{|c, i|
		if(c.active, {
			c.data= board.buffer[i];
			if(notchFilters.notNil, {
				c.data= notchFilters[i].filterN(c.data.last);
			});
			if(bandpassFilters.notNil, {
				c.data= bandpassFilters[i].filterN(c.data.last);
			});
		});
	};
};

Routine({
	var nextTime;
	while({win.isClosed.not}, {
		nextTime= Main.elapsedTime+(1/fps);
		if(channels[0].data.size>=fft.fftSize, {
			usr.refresh;
		});
		(nextTime-Main.elapsedTime).max(0.001).wait;
	});
}).play(AppClock);

~openbci= board;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
