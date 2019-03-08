//port of OpenBCI_GUI accelerometer widget, remake in supercollider by f.olofsson 2019
//MIT License, Copyright (c) 2018 OpenBCI, https://github.com/OpenBCI/OpenBCI_GUI/blob/master/LICENSE

//TODO test with ganglion and daisy

(
//var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match you board
var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
var buffer= OpenBCIbuf(board, 100, false, true).start;
var usr;
var f0= Font("Helvetiva", 16);
var f1= Font("Helvetiva", 14);
var f2= Font("Helvetiva", 20);
var colors= [
	Color.new255(224, 56, 45),
	Color.new255(49, 113, 89),
	Color.new255(54, 87, 158)
];
var data= List[[0, 0, 0]];

//--window
var win= Window("accelerometer widget", Rect(10, 100, 512, 338));
win.background= Color.white;
win.drawFunc= {
	var wb= win.bounds;
	var ub= usr.bounds;
	var amps, step, offset;
	Pen.smoothing= false;
	Pen.color= Color.black;
	Pen.stringAtPoint("Accelerometer", Point(10, 10), f0);
};
win.front;
CmdPeriod.doOnce({win.close});

//--plot
usr= UserView(win, Rect(*#[0.075, 0.15, 0.92, 0.8]*win.bounds.extent.asArray));
usr.animate= true;
usr.frameRate= 60;
usr.clearOnRefresh= true;
usr.drawFunc= {
	var width= usr.bounds.width*0.925;
	var height= (usr.bounds.height*0.95-148).max(22);
	var rad= 55;
	var f1center= "".bounds(f1).height*0.55;
	buffer.readAccel.do{|xyz| data.addFirst(xyz.linlin(-32768, 32767, -1, 1))};
	//data.addFirst({|i| (usr.frame/60+(i*0.75)).fold(-1, 1)}!3);  //test signal
	while({data.size>width}, {data.pop});

	Pen.stringAtPoint("X = % g".format((data[0][0]*4.096).round(1e-3)), Point(0, 10), f2, colors[0]);
	Pen.stringAtPoint("Y = % g".format((data[0][1]*4.096).round(1e-3)), Point(0, 45), f2, colors[1]);
	Pen.stringAtPoint("Z = % g".format((data[0][2]*4.096).round(1e-3)), Point(0, 80), f2, colors[2]);

	Pen.push;
	Pen.translate(width-(rad*2), 20);
	Pen.fillColor= Color.new255(245, 245, 245, 220);
	Pen.strokeColor= Color.new255(210, 210, 210);
	Pen.stringAtPoint("x", Point(rad*2.1, rad-f1center), f1, Color.black);
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
	Pen.lineTo(Point(data[0][0]*rad, 0));
	Pen.stroke;
	Pen.strokeColor= colors[1];
	Pen.moveTo(Point(0, 0));
	Pen.lineTo(cos(pi/4).asPoint*[rad, 0-rad]*data[0][1]);
	Pen.stroke;
	Pen.strokeColor= colors[2];
	Pen.moveTo(Point(0, 0));
	Pen.lineTo(Point(0, 0-data[0][2]*rad));
	Pen.stroke;
	Pen.pop;

	Pen.push;
	Pen.translate(0, 148);
	Pen.fillColor= Color.new255(245, 245, 245, 220);
	Pen.strokeColor= Color.new255(210, 210, 210);
	Pen.fillRect(Rect(0, 0, width, height));
	Pen.line(Point(0, height*0.5), Point(width, height*0.5));
	Pen.strokeRect(Rect(0, 0, width, height));
	Pen.stringAtPoint("+4g", Point(width+2, 0-f1center), f1, Color.black);
	Pen.stringAtPoint("0g", Point(width+8, height*0.5-f1center), f1, Color.black);
	Pen.stringAtPoint("-4g", Point(width+2, height-f1center), f1, Color.black);
	Pen.translate(0, height/2);
	3.do{|i|
		Pen.strokeColor= colors[i];
		data.do{|xyz, x|
			if(x==0, {
				Pen.moveTo(Point(width-x, 0-xyz[i]*height/2));
			}, {
				Pen.lineTo(Point(width-x, 0-xyz[i]*height/2));
			});
		};
		Pen.stroke;
	};
	Pen.pop;
};
usr.resize= 5;

~openbci= board;
)

~openbci.start;
~openbci.stop;
SerialPort.listDevices;
