//port of OpenBCI_GUI accelerometer widget, remake in supercollider by f.olofsson 2019
//MIT License, Copyright (c) 2018 OpenBCI, https://github.com/OpenBCI/OpenBCI_GUI/blob/master/LICENSE

//TODO test with ganglion and daisy
//TODO auto and sync menu selections

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var buffer= DataBuffer(board, 100, false, true).start;
var fps= 30;
var usr, pop1, pop2, pw, po;
var verticalScale, horizontalScale;
var f0= Font("Helvetiva", 16);
var f1= Font("Helvetiva", 14);
var f2= Font("Helvetiva", 10);
var f3= Font("Helvetiva", 20);
var colors= [
	Color.new255(224, 56, 45),
	Color.new255(49, 113, 89),
	Color.new255(54, 87, 158)
];
var data= List[[0, 0, 0]];

//--window
var win= Window("accelerometer widget", Rect(10, 100, 512, 360));
var ts= "Time (s)";
var as= "Acceleration (g)";
win.view.minSize= Size(330, 275);
win.background= Color.white;
win.drawFunc= {
	var wb= win.bounds;
	var ub= usr.bounds;
	var step;
	Pen.smoothing= false;
	Pen.color= Color.black;
	Pen.stringAtPoint("Accelerometer", Point(10, 10), f0);

	Pen.push;
	Pen.translate(ub.left, ub.bottom);
	Pen.stringAtPoint(ts, Point(ub.width-ts.bounds(f1).width/2, wb.height-ub.bottom/2), f1);
	Pen.line(Point(0, 6), Point(ub.width, 6));
	step= ub.width/(horizontalScale.size-1);
	horizontalScale.do{|h, i|
		var str;
		var x= i*step;
		if((h.frac>0).not, {h= h.asInteger});
		str= h.asString;
		Pen.stringAtPoint(str, Point(x-(str.bounds(f2).width/2), 12), f2);
		Pen.line(Point(x, 6), Point(x, 10));
	};
	Pen.stroke;
	Pen.pop;

	Pen.push;
	Pen.rotate(-0.5pi, wb.width/2, wb.height/2);
	Pen.translate(0-(wb.height-wb.width/2-(wb.height-ub.bottom)), wb.height-wb.width/2+ub.left);
	Pen.stringAtPoint(as, Point(ub.height-148-as.bounds(f1).width/2, 0-ub.left*0.85), f1);
	Pen.line(Point(0, -6), Point(ub.height-148, -6));
	step= ub.height-148/(verticalScale.size-1);
	verticalScale.do{|v, i|
		var str;
		var x= i*step;
		if((v.frac>0).not, {v= v.asInteger});
		str= v.asString;
		Pen.stringAtPoint(str, Point(x-(str.bounds(f2).width/2), -25), f2);
		Pen.line(Point(x, -6), Point(x, -10));
	};
	Pen.stroke;
	Pen.pop;
};
win.front;
CmdPeriod.doOnce({win.close});

//--plot
usr= UserView(win, Rect(*#[0.1, 0.15, 0.88, 0.7]*win.bounds.extent.asArray));
usr.animate= true;
usr.frameRate= fps;
usr.clearOnRefresh= false;
usr.drawFunc= {
	var ab, rad, step;
	var numPointsToDraw;

	if(buffer.accelBuffer.size>0, {  //skip frame if no new data arrived (25hz vs fps)

		ab= Rect(0, 148, usr.bounds.width, usr.bounds.height-148);  //plot area
		rad= 55;  //circleRadius

		numPointsToDraw= 25*horizontalScale[0].abs;  //25hz dependant
		buffer.readAccel.do{|xyz| data.addFirst(xyz)};
		while({data.size>numPointsToDraw}, {data.pop});

		Pen.fillColor= Color.white;
		Pen.fillRect(Rect(0, 0, ab.width, ab.top));

		Pen.stringAtPoint("X = % g".format((data[0][0]).round(1e-3)), Point(0, 10), f3, colors[0]);
		Pen.stringAtPoint("Y = % g".format((data[0][1]).round(1e-3)), Point(0, 45), f3, colors[1]);
		Pen.stringAtPoint("Z = % g".format((data[0][2]).round(1e-3)), Point(0, 80), f3, colors[2]);

		Pen.push;
		Pen.translate(ab.width-(rad*2.5), 20);
		Pen.fillColor= Color.new255(245, 245, 245, 220);
		Pen.strokeColor= Color.new255(210, 210, 210);
		Pen.stringAtPoint("x", Point(rad*2.1, rad-("x".bounds(f1).height*0.67)), f1, Color.black);
		Pen.stringAtPoint("y", Point(rad*1.75, 0), f1, Color.black);
		Pen.stringAtPoint("z", Point(rad-("z".bounds(f1).width/2), -20), f1, Color.black);
		Pen.fillOval(Rect(0, 0, rad*2, rad*2));
		Pen.line(Point(0, rad), Point(rad*2, rad));
		Pen.line(sin(pi/4).asPoint*[rad, 0-rad]+rad, sin(pi/4).asPoint*[0-rad, rad]+rad);
		Pen.line(Point(rad, 0), Point(rad, rad*2));
		Pen.strokeOval(Rect(0, 0, rad*2, rad*2));
		Pen.translate(rad, rad);
		Pen.width= 3;
		Pen.strokeColor= colors[0];
		Pen.moveTo(Point(0, 0));
		Pen.lineTo(Point(data[0][0]/4.096*rad, 0));
		Pen.stroke;
		Pen.strokeColor= colors[1];
		Pen.moveTo(Point(0, 0));
		Pen.lineTo(cos(pi/4).asPoint*[rad, 0-rad]*data[0][1]/4.096);
		Pen.stroke;
		Pen.strokeColor= colors[2];
		Pen.moveTo(Point(0, 0));
		Pen.lineTo(Point(0, 0-data[0][2]/4.096*rad));
		Pen.stroke;
		Pen.pop;

		Pen.push;
		Pen.translate(ab.left, ab.top);
		Pen.strokeColor= Color.black;
		step= ab.width/(horizontalScale.size-1);
		horizontalScale.do{|h, i|
			var x= i*step;
			Pen.line(Point(x, 0), Point(x, ab.height));
		};
		step= ab.height/(verticalScale.size-1);
		verticalScale.do{|v, i|
			var y= i*step;
			Pen.line(Point(0, y), Point(ab.width, y));
		};
		Pen.stroke;
		Pen.fillColor= Color.new255(245, 245, 245, 220);
		Pen.fillRect(Rect(0, 0, ab.width, ab.height));

		Pen.translate(0, ab.height/2);
		step= numPointsToDraw-1/ab.width;
		3.do{|i|
			var lastIndex= 0;
			var y= (data[0][i]/verticalScale[0]).clip(-1, 1)*ab.height*0.5;
			Pen.strokeColor= colors[i];
			Pen.moveTo(Point(ab.width, y));
			ab.width.do{|x|
				var xyz;
				var index= (x*step).round.asInteger;
				if(index>lastIndex and:{data[index]!=nil}, {
					xyz= data[index];
					y= (xyz[i]/verticalScale[0]).clip(-1, 1)*ab.height*0.5;
					Pen.lineTo(Point(ab.width-x, y));
					lastIndex= index;
				});
			};
			Pen.stroke;
		};
		Pen.pop;
		Pen.strokeColor= Color.new255(205, 205, 205);
		Pen.strokeRect(ab);
	});
};
usr.resize= 5;

//--menus
pw= win.bounds.width*0.125;
po= win.bounds.width-((pw+2)*2);
StaticText(win, Rect(po, 1, pw, 20)).align_(\center).string_("Vert Scale");
StaticText(win, Rect((pw+2)+po, 1, pw, 20)).align_(\center).string_("Window");
pop1= PopUpMenu(win, Rect(po, 20, pw, 20))
.items_(#["Auto", "1 g", "2 g", "4 g"])
.action_{|v|
	verticalScale= [
		(-2, -1 .. 2),  //TODO
		(-1, -0.6 .. 1),
		(-2, -1 .. 2),
		(-4, -2 .. 4)
	][v.value];
	win.refresh;
}.valueAction_(2);
pop2= PopUpMenu(win, Rect((pw+2)+po, 20, pw, 20))
.items_(#["Sync", "1 sec", "3 sec", "5 sec", "10 sec", "20 sec"])
.action_{|v|
	horizontalScale= [
		(-5..0),  //TODO
		(-1, -0.9 .. 0).round(0.1),
		(-3..0),
		(-5..0),
		(-10..0),
		(-20..0)
	][v.value];
	win.refresh;
}.valueAction_(3);
win.view.children.reject{|v| v==usr}.do{|v| v.resize_(3).font_(f2)};

~openbci= board;
)

~openbci.start;
~openbci.stop;
SerialPort.listDevices;
