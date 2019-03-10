//port of OpenBCI_GUI fft plot widget, remake in supercollider by f.olofsson 2019
//MIT License, Copyright (c) 2018 OpenBCI, https://github.com/OpenBCI/OpenBCI_GUI/blob/master/LICENSE

//TODO test with ganglion and daisy
//TODO how to do filters?
//TODO smooth here or in OpenBCIfft class?
//TODO (in)activate channels?

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b, r| b.start});  //synthetic test data
var fft= OpenBCIfft(board, 256).start;
var fps= 60;
var usr, pop1, pop2, pop3, pop4, pop5, pw;
var horizontalScale, verticalScale, maxFreq, maxAmp;
var smoothingFactor, prevData= 0.dup(fft.fftSize.div(2)).dup(board.numChannels);
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
		active: true
	)
}.dup(board.numChannels);

//--window
var win= Window("fft plot widget", Rect(10, 100, 512, 338));
var fs= "Frequency (Hz)";
var as= "Amplitude (uV)";
win.view.minSize= Size(400, 145);
win.background= Color.white;
win.drawFunc= {
	var wb= win.bounds;
	var ub= usr.bounds;
	var step;
	Pen.smoothing= false;
	Pen.color= Color.black;
	Pen.stringAtPoint("FFT Plot", Point(10, 10), f0);

	Pen.push;
	Pen.translate(ub.left, ub.bottom);
	Pen.stringAtPoint(fs, Point(ub.width-fs.bounds(f1).width/2, wb.height-ub.bottom/2), f1);
	Pen.line(Point(0, 6), Point(ub.width, 6));
	step= horizontalScale[1].linlin(horizontalScale[0], maxFreq, 0, ub.width-1);
	horizontalScale.do{|freq, i|
		var str= freq.asString;
		var x= freq.linlin(0, maxFreq, 0, ub.width-1);
		Pen.stringAtPoint(str, Point(x-(str.bounds(f2).width/2), 12), f2);
		Pen.line(Point(x, 6), Point(x, 10));
		Pen.line(Point(x, 0), Point(x, 0-ub.height));
	};
	Pen.stroke;
	Pen.pop;

	Pen.push;
	Pen.rotate(-0.5pi, wb.width/2, wb.height/2);
	Pen.translate(0-(wb.height-wb.width/2-(wb.height-ub.bottom)), wb.height-wb.width/2+ub.left);
	Pen.stringAtPoint(as, Point(ub.height-as.bounds(f1).width/2, 0-ub.left*0.75), f1);
	Pen.line(Point(0, -6), Point(ub.height, -6));
	step= verticalScale[pop3.value][1].explin(verticalScale[pop3.value][0], maxAmp, 0, ub.height-1);
	verticalScale[pop3.value].do{|v, i|
		var str= v.asString;
		var x;
		if(pop3.value==0, {
			x= v.explin(0.1, maxAmp, 0, ub.height-1);  //log
		}, {
			x= v.linlin(0, maxAmp, 0, ub.height-1);  //linear
		});
		Pen.stringAtPoint(str, Point(x-(str.bounds(f2).width/2), -30), f2);
		Pen.line(Point(x, -6), Point(x, -10));
		Pen.line(Point(x, 0), Point(x, ub.width));
		if(pop3.value==0, {
			9.do{|j|
				var xx= (j+1).explin(1, 10, 0, step);
				if((x+xx)<=(ub.height-1), {
					Pen.line(Point(x+xx, -6), Point(x+xx, -10));
					Pen.line(Point(x+xx, 0), Point(x+xx, ub.width));
				});
			};
		});
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
	var ub= usr.bounds;
	var step= ub.width/(maxFreq+1);
	var data;
	channels.do{|c, i|
		if(c.active, {
			data= fft.fft(i)*100000;
			if(pop4.value>0, {
				data= smoothingFactor*prevData[i]+((1-smoothingFactor*data));
				prevData[i]= data;
			});
			Pen.strokeColor= c.color;
			Pen.moveTo(Point(0, ub.height));
			data.do{|y, x|
				if(x<=(maxFreq+1) and:{x>0}, {
					if(pop3.value==0, {
						y= y.explin(0.1, maxAmp, ub.height, 0);
					}, {
						y= y.linlin(0, maxAmp, ub.height, 0);
					});
					Pen.lineTo(Point(x*step, y));
				});
			};
			Pen.stroke;
		});
	};
};
usr.resize= 5;

//--menus
pw= win.bounds.width*0.125;
StaticText(win, Rect(win.bounds.width-((pw+2)*5), 1, pw, 20)).align_(\center).string_("Max Freq");
StaticText(win, Rect(win.bounds.width-((pw+2)*4), 1, pw, 20)).align_(\center).string_("Max uV");
StaticText(win, Rect(win.bounds.width-((pw+2)*3), 1, pw, 20)).align_(\center).string_("Log/Lin");
StaticText(win, Rect(win.bounds.width-((pw+2)*2), 1, pw, 20)).align_(\center).string_("Smooth");
StaticText(win, Rect(win.bounds.width-((pw+2)*1), 1, pw, 20)).align_(\center).string_("Filters?");
pop1= PopUpMenu(win, Rect(win.bounds.width-((pw+2)*5), 20, pw, 20))
.items_(#["20 Hz", "40 Hz", "60 Hz", "100 Hz", "120 Hz", "250 Hz", "500 Hz", "800 Hz"])
.action_{|v|
	maxFreq= v.item.asInteger;
	horizontalScale= #[
		[2, 6, 10, 14, 18],
		[10, 20, 30, 40],
		[10, 20, 30, 40, 50, 60],
		[10, 30, 50, 70, 90],
		[10, 30, 50, 70, 90, 110],
		[30, 80, 130, 180, 230],
		[100, 200, 300, 400, 500],
		[100, 300, 500, 700],
	][v.value];
	win.refresh;
}.valueAction_(2);
pop2= PopUpMenu(win, Rect(win.bounds.width-((pw+2)*4), 20, pw, 20))
.items_(#["10 uV", "50 uV", "100 uV", "1000 uV"])
.action_{|v|
	maxAmp= v.item.asInteger;
	verticalScale= #[
		[[0.1, 1, 10], [1, 2, 3, 4, 5, 6, 7, 8, 9]],
		[[0.1, 1, 10], [1, 7, 13, 19, 25, 31, 37, 43, 49]],
		[[0.1, 1, 10, 100], [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]],
		[[0.1, 1, 10, 100, 1000], [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]]
	][v.value];
	win.refresh;
}.valueAction_(2);
pop3= PopUpMenu(win, Rect(win.bounds.width-((pw+2)*3), 20, pw, 20))
.items_(#["Log", "Linear"])
.action_{win.refresh}.value_(0);
pop4= PopUpMenu(win, Rect(win.bounds.width-((pw+2)*2), 20, pw, 20))
.items_(#["0.0", "0.5", "0.75", "0.9", "0.95", "0.98"])
.action_{|v| smoothingFactor= v.item.asFloat}.valueAction_(3);
pop5= PopUpMenu(win, Rect(win.bounds.width-((pw+2)*1), 20, pw, 20))
.items_(#["Filtered", "Unfilt."])
.action_{|v| [v.value, v.item].postln}.value_(0);
win.view.children.reject{|v| v==usr}.do{|v| v.resize_(3).font_(f2)};

~openbci= board;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
