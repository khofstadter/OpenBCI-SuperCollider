//port of OpenBCI_GUI time series widget, remake in supercollider by f.olofsson 2019
//MIT License, Copyright (c) 2018 OpenBCI, https://github.com/OpenBCI/OpenBCI_GUI/blob/master/LICENSE

//TODO railed warnings
//TODO test with wifi shield
//TODO test with ganglion and daisy
//TODO (in)activate channels + off button
//TODO impedance per channel + ohm symbol
//TODO hardware settings?

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b| b.start});
var notchFilter= DataFilterNotch('50');
var bandpassFilter= DataFilterBandpass('1-50');
var buffer= OpenBCIbuf(board, accelActive: false).start;
var fps= 60;
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
		active: true,
		impedance: false
	)
}.dup(board.numChannels);
var data= List[0.dup(channels.size)];

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
			win.refresh;
		}, {
			if(c.omega.containsPoint(Point(x, y)), {
				c.impedance= c.impedance.not;
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
	var step;
	var channelHeight= ub.height-2/channels.size;
	var numPointsToDraw;

	numPointsToDraw= board.currentSampleRate*horizontalScale[0].abs;  //sr dependant
	buffer.readData.do{|d| data.insert(0, d)};
	while({data.size>numPointsToDraw}, {data.pop});

	Pen.fillColor= Color.new255(255, 255, 255, 200);
	step= numPointsToDraw-1/ub.width;
	channels.do{|c, i|
		var uVrms= 0, uVrmsCnt= 0, uVrmsRect, uVrmsStr;
		var y, lastIndex;
		if(c.active, {
			lastIndex= 0;
			y= 1-(data[0][i]/maxAmp).clip(-1, 1)*channelHeight*0.5+1;
			Pen.strokeColor= c.color;
			Pen.moveTo(Point(ub.width, y));
			ub.width.do{|x|
				var val;
				var index= (x*step).round.asInteger;
				if(index>lastIndex and:{data[index]!=nil}, {
					val= data[index];
					uVrms= uVrms+pow(val[i], 2);
					uVrmsCnt= uVrmsCnt+1;
					y= 1-(val[i]/maxAmp).clip(-1, 1)*channelHeight*0.5+1;
					Pen.lineTo(Point(ub.width-x, y));
					lastIndex= index;
				});
			};
			Pen.stroke;

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
	win.refresh;
}.valueAction_(2);
btn1= Button(win, Rect((pw+2)*2+po, 20, pw/2, 20)).states_(
	[["Off"]]++DataFilterNotch.keys.collect{|x| [x.asString+"Hz"]}
).action_{|v|
	board.removeFilter(notchFilter);
	if(v.value>0, {
		notchFilter= DataFilterNotch(DataFilterNotch.keys[v.value-1]);
		board.addFilter(notchFilter);
	});
}.valueAction_(1);
btn2= Button(win, Rect((pw+2)*2.5+po, 20, pw/2, 20)).states_(
	[["Off"]]++DataFilterBandpass.keys.collect{|x| [x.asString]}
).action_{|v|
	board.removeFilter(bandpassFilter);
	if(v.value>0, {
		bandpassFilter= DataFilterBandpass(DataFilterBandpass.keys[v.value-1]);
		board.addFilter(bandpassFilter);
	});
}.valueAction_(1);
win.view.children.reject{|v| v==usr}.do{|v| v.resize_(3).font_(f2)};

~openbci= board;
)



~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
~openbci.filters