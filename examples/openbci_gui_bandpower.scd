//port of OpenBCI_GUI band power widget, remake in supercollider by f.olofsson 2019
//MIT License, Copyright (c) 2018 OpenBCI, https://github.com/OpenBCI/OpenBCI_GUI/blob/master/LICENSE

//TODO test with ganglion and daisy

(
var activeChannels= #[0, 1, 2, 3, 4, 5, 6, 7];
var bands= #[
	["DELTA", 1, 4],  //name, min, max (Hz)
	["THETA", 4, 8],
	["ALPHA", 8, 13],
	["BETA", 13, 30],
	["GAMMA", 30, 55]
];
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var notchFilter, bandpassFilter, smoothFilters;
var fft= DataFFT(board, 256);
var fps= 30;
var bandsBuffer= {List.fill(bands.size, {List.fill(fps, {0})})}.dup(board.numChannels);  //1sec
var usr, pop1, btn1, btn2, pw, po;
var verticalScale= #[0.1, 1, 10, 100];
var f0= Font("Helvetiva", 16);
var f1= Font("Helvetiva", 14);
var f2= Font("Helvetiva", 10);
var colors= [
	Color.new255(184, 181, 247),
	Color.new255(130, 122, 251),
	Color.new255(80, 64, 254),
	Color.new255(36, 0, 255)
];
var channels= {|i|
	(
		active: activeChannels.includes(i)
	)
}.dup(board.numChannels);

//--window
var win= Window("band power widget", Rect(10, 100, 512, 320));
var as= "(uV)^2 / Hz per channel";
win.view.minSize= Size(436, 145);
win.background= Color.white;
win.drawFunc= {
	var wb= win.bounds;
	var ub= usr.bounds;
	var step;
	Pen.smoothing= false;
	Pen.color= Color.black;
	Pen.stringAtPoint("Band Power", Point(10, 10), f0);

	Pen.push;
	Pen.translate(ub.left, ub.bottom);
	step= ub.width-1/bands.size;
	bands.do{|arr, i|
		var x= step*i+(step*0.5);
		Pen.stringAtPoint(arr[0], Point(x-(arr[0].bounds(f2).width/2), 12), f2);
	};
	Pen.stroke;
	Pen.pop;

	Pen.push;
	Pen.rotate(-0.5pi, wb.width/2, wb.height/2);
	Pen.translate(0-(wb.height-wb.width/2-(wb.height-ub.bottom)), wb.height-wb.width/2+ub.left);
	Pen.stringAtPoint(as, Point(ub.height-as.bounds(f1).width, 0-ub.left*0.75), f1);
	Pen.line(Point(0, -6), Point(ub.height, -6));
	step= verticalScale[1].explin(verticalScale[0], 100, 0, ub.height-1);
	verticalScale.do{|v, i|
		var str= v.asString;
		var x= v.explin(0.1, 100, 0, ub.height-1);  //log
		Pen.stringAtPoint(str, Point(x-(str.bounds(f2).width/2), -30), f2);
		Pen.line(Point(x, -6), Point(x, -10));
		Pen.line(Point(x, 0), Point(x, ub.width));
		9.do{|j|
			var xx= (j+1).explin(1, 10, 0, step);
			if((x+xx)<=(ub.height-1), {
				Pen.line(Point(x+xx, -6), Point(x+xx, -10));
				Pen.line(Point(x+xx, 0), Point(x+xx, ub.width));
			});
		};
	};
	Pen.stroke;
	Pen.pop;
};
win.front;
CmdPeriod.doOnce({win.close});

//--plot
usr= UserView(win, Rect(*#[0.14, 0.19, 0.8, 0.64]*win.bounds.extent.asArray));
usr.background= Color.new255(245, 245, 245, 220);
usr.animate= true;
usr.frameRate= fps;
usr.clearOnRefresh= true;
usr.drawFunc= {
	var data;
	var ub= usr.bounds;
	var step= ub.width-1/bands.size;
	var indices= bands.collect{|b| [fft.freqToIndex(b[1]), fft.freqToIndex(b[2])]};
	var factor= fft.fftSize/board.currentSampleRate;
	channels.do{|c, i|
		if(c.active, {
			data= board.buffer[i];
			if(btn1.value>0, {
				data= notchFilter.filter(data);
			});
			if(btn2.value>0, {
				data= bandpassFilter.filter(data);
			});
			data= fft.fft(data);
			if(pop1.value>0, {
				data= smoothFilters[i].filter(data);
			});
			bands.do{|b, j|
				var psdArr= data.copyRange(indices[j][0], indices[j][1]-1)**2*factor/4;
				bandsBuffer[i][j].pop;
				bandsBuffer[i][j].insert(0, psdArr.sum);
			};
		});
	};
	Pen.strokeColor= Color.blue;
	bands.do{|b, j|
		var x, y, arr= Array.new;
		channels.do{|c, i|
			if(c.active, {
				arr= arr++bandsBuffer[i][j];
			});
		};
		x= step*j+1;
		y= arr.mean.explin(0.1, 100, ub.height, 0);
		Pen.fillColor= colors.wrapAt(j);
		Pen.fillRect(Rect(x, y, step-2, ub.height-y));
		Pen.strokeRect(Rect(x, y, step-2, ub.height-y));
	};
};
usr.resize= 5;

//--menus
pw= win.bounds.width*0.125;
po= win.bounds.width-((pw+2)*2.5);
StaticText(win, Rect(po, 1, pw, 20)).align_(\center).string_("Smooth");
StaticText(win, Rect((pw+2)+po, 1, pw, 20)).align_(\center).string_("Filters");
pop1= PopUpMenu(win, Rect(po, 20, pw, 20))
.items_(#["0.0", "0.5", "0.75", "0.9", "0.95", "0.98"])
.action_{|v|
	smoothFilters= {DataSmoothing(v.item.asFloat)}.dup(board.numChannels);
}.valueAction_(3);
btn1= Button(win, Rect((pw+2)+po, 20, pw/2, 20)).states_(
	[["Off"]]++DataFilterNotch.keys.collect{|x| [x.asString+"Hz"]}
).action_{|v|
	if(v.value>0, {
		notchFilter= DataFilterNotch(DataFilterNotch.keys[v.value-1]);
	}, {
		notchFilter= nil;
	});
}.valueAction_(1);
btn2= Button(win, Rect((pw+2)*1.5+po, 20, pw/2, 20)).states_(
	[["Off"]]++DataFilterBandpass.keys.collect{|x| [x.asString]}
).action_{|v|
	if(v.value>0, {
		bandpassFilter= DataFilterBandpass(DataFilterBandpass.keys[v.value-1]);
	}, {
		bandpassFilter= nil;
	});
}.valueAction_(1);
win.view.children.reject{|v| v==usr}.do{|v| v.resize_(3).font_(f2)};

~openbci= board;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
