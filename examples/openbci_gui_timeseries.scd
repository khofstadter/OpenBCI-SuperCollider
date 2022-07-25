//port of OpenBCI_GUI time series widget, remake in supercollider by f.olofsson 2019
//MIT License, Copyright (c) 2018 OpenBCI, https://github.com/OpenBCI/OpenBCI_GUI/blob/master/LICENSE

//TODO test with wifi shield - work out samplerate
//TODO test with ganglion and daisy
//TODO hardware settings?

(
var activeChannels= #[0, 1, 2, 3, 4, 5, 6, 7];
//var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var threshRailed= 2.pow(23)-1000*board.uVScale(24);
var threshNearRailed= 2.pow(23)*0.9*board.uVScale(24);
var notchFilters, bandpassFilters;
var fps= 60;
var usr, pop1, pop2, btn1, btn2, pw, po;
var img, imgDrawFunc, imgPixels;
var horizontalScale, maxAmp;
var f0= Font("Helvetiva", 16);
var f1= Font("Helvetiva", 14);
var f2= Font("Helvetiva", 10);
var colors= [
	Color.new255(129, 129, 129),
	Color.new255(124, 75, 141),
	Color.new255(54, 87, 158),
	Color.new255(49, 113, 89),
	Color.new255(221, 178, 13),
	Color.new255(253, 94, 52),
	Color.new255(224, 56, 45),
	Color.new255(162, 82, 49)
];
var channels= {|i|
	(
		color: colors.wrapAt(i),
		active: activeChannels.includes(i),
		impedance: false,
		data: [],
		railed: false,
		nearRailed: false,
		uVrms: RingBuffer(100, FloatArray),
		lastPenPositionY: 0
	)
}.dup(board.numChannels);
var std= {|arr|  //standard deviation
	var val= 0;
	var average= arr.mean;
	arr.do{|a| val= val+pow(a-average, 2)};
	sqrt(val= val/arr.size);
};
var impedance= {|uV|
	var impedance= sqrt(2)*uV*1e-6/6e-9;
	impedance= impedance-2200;  //NOTE: cyton board only 2K2 resistor
};

//--window
var win= Window("time series widget", Rect(10, 100, 512, 576));
var ts= "Time (s)";
var np= Point("0".bounds(f1).width/2, "0".bounds(f1).height/2);
var op= Point("Ω".bounds(f1).width/2, "Ω".bounds(f1).height/2);
win.view.minSize= Size(328, 252);
win.background= Color.white;
win.drawFunc= {
	var wb= win.bounds;
	var ub= usr.bounds;
	var step;
	var offsetx= 10, offsety= ub.top;
	Pen.smoothing= false;
	Pen.color= Color.black;
	Pen.stringAtPoint("Time Series", Point(10, 10), f0);

	Pen.push;
	Pen.translate(offsetx, offsety);
	step= (ub.height-2)/channels.size;
	(channels.size+1).do{|i|
		var y= i*step+1;
		Pen.line(Point(ub.left-10, y), Point(ub.width+40, y));
	};
	Pen.stroke;
	Pen.strokeColor= Color.new255(200, 200, 200);
	(channels.size+1).do{|i|
		var y= i*step+1;
		Pen.line(Point(0, y), Point(ub.left-10, y));
	};
	Pen.line(Point(0, 0), Point(0, ub.height));
	Pen.stroke;
	channels.do{|c, i|
		var y= i*step+1;
		var circlePoint= Point(12, step/2+y);
		var circleRect= Rect.aboutPoint(circlePoint, 10, 10);
		var omegaPoint= Point(32, step/2+y);
		var omegaRect= Rect.aboutPoint(omegaPoint, 10, 10);
		c.put(\circle, circleRect+[offsetx, offsety]);
		c.put(\omega, omegaRect+[offsetx, offsety]);
		if(c.active, {
			Pen.fillColor= c.color;
		}, {
			Pen.fillColor= Color.new255(100, 100, 100);
		});
		Pen.fillOval(circleRect);
		Pen.stringAtPoint((i+1).asString, circlePoint-np, f1, Color.black);
		if(c.impedance, {
			Pen.fillColor= Color.new255(127, 127, 127);
			Pen.fillOval(omegaRect);
		}, {
			Pen.fillColor= Color.white;
			Pen.fillOval(omegaRect);
		});
		Pen.stringAtPoint("Ω", omegaPoint-op, f1, Color.black);
	};
	Pen.stroke;
	Pen.pop;

	Pen.push;
	Pen.translate(ub.left, ub.bottom);
	Pen.stringAtPoint(ts, Point(ub.width-ts.bounds(f1).width/2, wb.height-ub.bottom/2), f1);
	Pen.line(Point(0, 6), Point(ub.width, 6));
	step= ub.width/(horizontalScale.size-1);
	horizontalScale.do{|t, i|
		var str;
		var x= i*step;
		if((t.frac>0).not, {t= t.asInteger});
		str= t.asString;
		Pen.stringAtPoint(str, Point(x-(str.bounds(f2).width/2), 12), f2);
		Pen.line(Point(x, 6), Point(x, 10));
		Pen.line(Point(x, 0), Point(x, 0-ub.height));
	};
	Pen.stroke;
	Pen.pop;
};
win.view.mouseMoveAction= {|v, x, y|
	channels.do{|c, i|
		if(c.circle.containsPoint(Point(x, y)), {
			c.active= c.active.not;
			if(c.active, {board.on(i+1)}, {board.off(i+1)});
			win.refresh;
		}, {
			if(c.omega.containsPoint(Point(x, y)), {
				if(board.respondsTo(\impedance), {
					c.impedance= c.impedance.not;
					board.impedance(i+1, 0, c.impedance.binaryValue);
					win.refresh;
				});
			});
		});
	};
};
win.view.mouseUpAction= win.view.mouseMoveAction;
win.front;
CmdPeriod.doOnce({win.close});

//--plot
usr= UserView(win, Rect(*#[0.1, 0.08, 0.88, 0.84]*win.bounds.extent.asArray));
img= Image(usr.bounds.width.asInteger, usr.bounds.height.asInteger);
img.interpolation= \fast;
imgPixels= img.pixels;
usr.background= Color.new255(245, 245, 245, 220);
usr.clearOnRefresh= true;
usr.drawFunc= {
	var uw= usr.bounds.width;
	var uh= usr.bounds.height;
	var channelHeight= uh-2/channels.size;
	var impedanceVal, impedanceRect, impedanceStr;
	var uVrmsRect, uVrmsStr;

	Pen.drawImage(Rect(0, 0, uw, uh), img);

	Pen.fillColor= Color.new255(255, 255, 255, 200);
	channels.do{|c, i|

		if(c.active, {
			if(c.impedance, {
				if(c.railed, {
					impedanceStr= "RAILED";
				}, {
					impedanceVal= impedance.value(std.value(c.data.keep(0-board.currentSampleRate)));
					impedanceStr= (impedanceVal/1000).round(0.01).asString+"kOhm ";
				});
				impedanceRect= impedanceStr.bounds(f2);
				impedanceRect= impedanceRect.moveTo(2, channelHeight-impedanceRect.height-1);
				Pen.fillRect(impedanceRect);
				Pen.stringLeftJustIn(impedanceStr, impedanceRect, f2, Color.black);
			});

			if(c.railed, {
				uVrmsStr= "RAILED";
			}, {
				uVrmsStr= c.uVrms.array.mean.sqrt.round(0.1).asString+"uVrms";
				if(c.nearRailed, {
					uVrmsStr= "NEAR RAILED - "++uVrmsStr;
				});
			});
			uVrmsRect= uVrmsStr.bounds(f2);
			uVrmsRect= uVrmsRect.moveTo(uw-uVrmsRect.width-2, channelHeight-uVrmsRect.height-1);
			Pen.fillRect(uVrmsRect);
			Pen.stringRightJustIn(uVrmsStr, uVrmsRect, f2, Color.black);
		});

		Pen.translate(0, channelHeight);
	};
};
usr.resize= 5;
usr.canFocus= false;
imgDrawFunc= {
	img.draw{
		var channelHeight= img.height-2/channels.size;
		var length= horizontalScale[0].abs.asInteger*board.currentSampleRate;

		img.fill(Color.clear);

		channels.do{|c, i|
			Pen.strokeColor= c.color;
			if(c.active, {
				c.railed= false;
				c.nearRailed= false;
				c.data.copyToEnd(c.data.size-length).do{|val, x|
					var y= 1-(val/maxAmp).clip(-1, 1)*channelHeight*0.5+1;
					if(x==0, {
						Pen.moveTo(Point(0, y));
					}, {
						Pen.lineTo(Point(x.linlin(0, length, 0, img.width), y));
					});
					if(val.abs>=threshNearRailed, {
						c.nearRailed= true;
						if(val.abs>=threshRailed, {
							c.railed= true;
						});
					});
					c.uVrms.overwrite(pow(val, 2));
				};
			}, {
				Pen.moveTo(Point(0, channelHeight*0.5));
				Pen.lineTo(Point(img.width, channelHeight*0.5));
			});
			Pen.stroke;
			Pen.translate(0, channelHeight);
		};
	};
};

//--menus
pw= win.bounds.width*0.144;
po= win.bounds.width-((pw+2)*3);
StaticText(win, Rect(po, 1, pw, 20)).align_(\center).string_("Vert Scale");
StaticText(win, Rect((pw+2)+po, 1, pw, 20)).align_(\center).string_("Window");
StaticText(win, Rect((pw+2)*2+po, 1, pw, 20)).align_(\center).string_("Filters");
pop1= PopUpMenu(win, Rect(po, 20, pw, 20))
.items_(#["Auto", "50 uV", "100 uV", "200 uV", "400 uV", "1000 uV", "10000 uV"])
.action_{|v|
	maxAmp= v.item.asInteger;
	win.refresh;
}.valueAction_(2);
pop2= PopUpMenu(win, Rect((pw+2)+po, 20, pw, 20))
.items_(#["1 sec", "3 sec", "5 sec", "10 sec", "20 sec"])
.action_{|v|
	horizontalScale= [
		(-1, -0.9 .. 0).round(0.1),
		(-3..0),
		(-5..0),
		(-10..0),
		(-20..0)
	][v.value];
	board.bufferSize= horizontalScale[0].abs.asInteger*board.currentSampleRate;
	notchFilters.do{|f| f.bufferSize_(board.bufferSize)};
	bandpassFilters.do{|f| f.bufferSize_(board.bufferSize)};
	win.refresh;
}.valueAction_(2);
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
win.onClose= {img.free};

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
		imgDrawFunc.value;
		usr.refresh;
		(nextTime-Main.elapsedTime).max(0.001).wait;
	});
}).play(AppClock);

~openbci= board;
)



~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
