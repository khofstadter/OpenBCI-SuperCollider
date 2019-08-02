//port of OpenBCI_GUI time series widget, remake in supercollider by f.olofsson 2019
//MIT License, Copyright (c) 2018 OpenBCI, https://github.com/OpenBCI/OpenBCI_GUI/blob/master/LICENSE

//TODO railed warnings
//TODO test with wifi shield - work out samplerate
//TODO test with ganglion and daisy
//TODO hardware settings?

(
var activeChannels= #[0, 1, 2, 3, 4, 5, 6, 7];
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var notchFilter, bandpassFilter;
var numPointsToDraw;
var fps= 30;
var usr, pop1, pop2, btn1, btn2, pw, po;
var horizontalScale, maxAmp;
var f0= Font("Helvetiva", 16);
var f1= Font("Helvetiva", 14);
var f2= Font("Helvetiva", 10);
var rmsSize= Point("999.9 uVrms".bounds(f2).width, f2.size*1.5);
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
		impedance: false
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
				c.impedance= c.impedance.not;
				board.impedance(i+1, 0, c.impedance.binaryValue);
				win.refresh;
			});
		});
	};
};
win.view.mouseUpAction= win.view.mouseMoveAction;
win.front;
CmdPeriod.doOnce({win.close});

//--plot
usr= UserView(win, Rect(*#[0.1, 0.08, 0.88, 0.84]*win.bounds.extent.asArray));
usr.background= Color.new255(245, 245, 245, 220);
usr.animate= true;
usr.frameRate= fps;
usr.clearOnRefresh= true;
usr.drawFunc= {
	var ub= usr.bounds;
	var step= numPointsToDraw-1/ub.width;
	var channelHeight= ub.height-2/channels.size;
	Pen.fillColor= Color.new255(255, 255, 255, 200);
	channels.do{|c, i|
		var impedanceVal, impedanceRect, impedanceStr;
		var uVrms= 0, uVrmsCnt= 0, uVrmsRect, uVrmsStr;
		var y, data;
		if(c.active, {
			data= board.buffer[i];
			if(notchFilter.notNil, {
				data= notchFilter.filter(data);
			});
			if(bandpassFilter.notNil, {
				data= bandpassFilter.filter(data);
			});
			y= 1-(data[0]/maxAmp).clip(-1, 1)*channelHeight*0.5+1;
			Pen.strokeColor= c.color;
			Pen.moveTo(Point(ub.width, y));
			ub.width.do{|x|
				var index= data.size-1-(x*step).round.asInteger;
				var val= data[index];
				uVrms= uVrms+pow(val, 2);
				uVrmsCnt= uVrmsCnt+1;
				y= 1-(val/maxAmp).clip(-1, 1)*channelHeight*0.5+1;
				Pen.lineTo(Point(ub.width-x, y));
			};
			Pen.stroke;

			if(c.impedance, {
				impedanceVal= impedance.value(std.value(data.keep(0-board.currentSampleRate)));
				impedanceStr= (impedanceVal/1000).round(0.01).asString+"kOhm ";
				impedanceRect= impedanceStr.bounds(f2);
				impedanceRect= impedanceRect.moveTo(2, channelHeight-impedanceRect.height-1);
				Pen.fillRect(impedanceRect);
				Pen.stringLeftJustIn(impedanceStr, impedanceRect, f2, Color.black);
			});

			if(uVrmsCnt>0, {
				uVrms= (uVrms/uVrmsCnt).sqrt;
				uVrmsStr= uVrms.round(0.1).asString+"uVrms";
				uVrmsRect= uVrmsStr.bounds(f2);
				uVrmsRect= uVrmsRect.moveTo(ub.width-uVrmsRect.width-2, channelHeight-uVrmsRect.height-1);
				Pen.fillRect(uVrmsRect);
				Pen.stringRightJustIn(uVrmsStr, uVrmsRect, f2, Color.black);
			});
		});
		Pen.translate(0, channelHeight);
	};
};
usr.resize= 5;

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
	numPointsToDraw= board.currentSampleRate*horizontalScale[0].abs.asInteger;  //sr dependant
	board.bufferSize_((numPointsToDraw*2).max(usr.bounds.width*2));
	win.refresh;
}.valueAction_(2);
btn1= Button(win, Rect((pw+2)*2+po, 20, pw/2, 20)).states_(
	[["Off"]]++DataFilterNotch.keys.collect{|x| [x.asString+"Hz"]}
).action_{|v|
	if(v.value>0, {
		notchFilter= DataFilterNotch(DataFilterNotch.keys[v.value-1]);
	}, {
		notchFilter= nil;
	});
}.valueAction_(1);
btn2= Button(win, Rect((pw+2)*2.5+po, 20, pw/2, 20)).states_(
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
