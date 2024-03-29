//port of OpenBCI_GUI fft plot widget, remake in supercollider by f.olofsson 2019
//MIT License, Copyright (c) 2018 OpenBCI, https://github.com/OpenBCI/OpenBCI_GUI/blob/master/LICENSE

//adapted to calculate theta and gamma and store in global variables
//draw 0 - pause all drawing to save cpu
//draw 1 - only draw thresholds and average values
//draw 2 - draw everyhing including fft data

//TODO remove high amp ch1 in a SyntheticData subcalss;
//TODO test with ganglion and daisy
//TODO (in)activate channels?

(
var activeChannels= #[0,1,2,3,4,5,6,7];
var thetaBand= [0, 4, 8];  //channel, min, max (in Hz)
var gammaBand= [1, 35, 45];  //channel, min, max (in Hz)
var loThetaEnergy= 0, hiThetaEnergy= 10;  //vertical thresholds - adjust min and max for theta
var loGammaEnergy= 0, hiGammaEnergy= 10;  //vertical thresholds - adjust min and max for gamma
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("/Users/khofstadter/Dropbox/PhD/raw_eeg_data/shamanic_soundscape/mama/OpenBCI-RAW-2019-10-01_10-31-39_sc.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var notchFilters, bandpassFilters, smoothFilters;
var fft= DataFFT(board, 256);
var fps= 60, animate= false;
var downSample= 65;  //only draw this many samples
var allData= Array.newClear(board.numChannels);  //an array of arrays with fft data
var drawModes= #[\Paused, \NoData, \DownSampl, \Complete];
var calculations;
var energyThetaAvg= 0, energyGammaAvg= 0;  //the current calulated averages
var usr, btn0, pop1, pop2, pop3, pop4, btn1, btn2, pw, po;
var horizontalScale, verticalScale, maxFreq, maxAmp;
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
		data: [],
		uVrms: 0.0
	)
}.dup(board.numChannels);

//--window
var win= Window("fft plot widget", Rect(1000, 1000, 512, 338));//changed by kh to be top right;
var fs= "Frequency (Hz)";
var as= "Amplitude (uV)";
win.view.minSize= Size(502, 145);
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
usr.clearOnRefresh= true;
usr.drawFunc= {
	var uh= usr.bounds.height;
	var step= usr.bounds.width/(maxFreq+1);
	var xstep= if(drawMode==2, {step*fft.fftSize2/downSample}, {step});
	var drawLog= pop3.value==0;
	var drawMode= btn0.value;
	allData.do{|data, i|
		var energyX, energyX2, energyY, energyY2, energyYtheta, energyYgamma;
		if(channels[i].active, {
			Pen.width= 1;
			if(drawMode>=2, {
				if(drawMode==2, {
					// data= data.resamp0(downSample);  //use resamp1 for interpolation
					data= data.clump(3).collect{|x| x.maxItem};
					xstep= step*3;

				});
				Pen.strokeColor= channels[i].color;
				Pen.moveTo(Point(0, uh));
				data.do{|y, x|
					if(x<=(maxFreq+1) and:{x>0}, {
						if(drawLog, {
							y= y.explin(0.1, maxAmp, uh, 0);
						}, {
							y= y.linlin(0, maxAmp, uh, 0);
						});
						Pen.lineTo(Point(x*xstep, y));
					});
				};

				Pen.stroke;
			});

			//--optional draw marker lines for min+max
			Pen.strokeColor= Color.red(1, 0.5);
			energyX= thetaBand[1]*step;
			energyX2= thetaBand[2]*step;
			if(drawLog, {
				energyY= ~loThetaEnergy.explin(0.1, maxAmp, uh, 0);
				energyY2= ~hiThetaEnergy.explin(0.1, maxAmp, uh, 0);
				energyYtheta= energyThetaAvg.explin(0.1, maxAmp, uh, 0);
			}, {
				energyY= ~loThetaEnergy.linlin(0, maxAmp, uh, 0);
				energyY2= ~hiThetaEnergy.linlin(0, maxAmp, uh, 0);
				energyYtheta= energyThetaAvg.linlin(0, maxAmp, uh, 0);
			});
			Pen.moveTo(Point(energyX+4, energyY));
			Pen.lineTo(Point(energyX2-4, energyY));
			Pen.moveTo(Point(energyX+4, energyY2));
			Pen.lineTo(Point(energyX2-4, energyY2));
			Pen.stroke;
			Pen.width= 3;
			Pen.moveTo(Point(energyX, energyYtheta));
			Pen.lineTo(Point(energyX2, energyYtheta));
			Pen.stroke;

			Pen.width= 1;
			Pen.strokeColor= Color.green(1, 0.5);
			energyX= gammaBand[1]*step;
			energyX2= gammaBand[2]*step;
			if(drawLog, {
				energyY= ~loGammaEnergy.explin(0.1, maxAmp, uh, 0);
				energyY2= ~hiGammaEnergy.explin(0.1, maxAmp, uh, 0);
				energyYgamma= energyGammaAvg.explin(0.1, maxAmp, uh, 0);
			}, {
				energyY= ~loGammaEnergy.linlin(0, maxAmp, uh, 0);
				energyY2= ~hiGammaEnergy.linlin(0, maxAmp, uh, 0);
				energyYgamma= energyGammaAvg.linlin(0, maxAmp, uh, 0);
			});
			Pen.moveTo(Point(energyX+4, energyY));
			Pen.lineTo(Point(energyX2-4, energyY));
			Pen.moveTo(Point(energyX+4, energyY2));
			Pen.lineTo(Point(energyX2-4, energyY2));
			Pen.stroke;
			Pen.width= 3;
			Pen.moveTo(Point(energyX, energyYgamma));
			Pen.lineTo(Point(energyX2, energyYgamma));
			Pen.stroke;
		});
	};
};
usr.resize= 5;
usr.canFocus= false;

//--menus
pw= win.bounds.width*0.125;
po= win.bounds.width-((pw+2)*6.5);
btn0= Button(win, Rect(po, 20, pw, 20))
.states_(drawModes.collect{|symbol| [symbol.asString]})
.action_({|view|
	if(view.value==0, {
		animate= false;
	}, {
		animate= true;
	});
}).valueAction_(1);
StaticText(win, Rect((pw+2)+po, 1, pw, 20)).align_(\center).string_("Max Freq");
StaticText(win, Rect((pw+2)*2+po, 1, pw, 20)).align_(\center).string_("Max uV");
StaticText(win, Rect((pw+2)*3+po, 1, pw, 20)).align_(\center).string_("Log/Lin");
StaticText(win, Rect((pw+2)*4+po, 1, pw, 20)).align_(\center).string_("Smooth");
StaticText(win, Rect((pw+2)*5+po, 1, pw, 20)).align_(\center).string_("Filters");
pop1= PopUpMenu(win, Rect((pw+2)+po, 20, pw, 20))
.items_(#["20 Hz", "40 Hz", "60 Hz", "100 Hz", "120 Hz", "250 Hz", "500 Hz", "800 Hz"])
.action_{|v|
	maxFreq= v.item.asInteger;
	horizontalScale= [
		(2, 6 .. 18),
		(10, 20 .. 40),
		(10, 20 .. 60),
		(10, 30 .. 90),
		(10, 30 .. 110),
		(30, 80 .. 230),
		(100, 200 .. 500),
		(100, 300 .. 700)
	][v.value];
	win.refresh;
}.valueAction_(2);
pop2= PopUpMenu(win, Rect((pw+2)*2+po, 20, pw, 20))
.items_(#["10 uV", "50 uV", "100 uV", "1000 uV"])
.action_{|v|
	maxAmp= v.item.asInteger;
	verticalScale= [
		[[0.1, 1, 10], (1..9)],
		[[0.1, 1, 10], (1, 7 .. 49)],
		[[0.1, 1, 10, 100], (10, 20 .. 100)],
		[[0.1, 1, 10, 100, 1000], (100, 200 .. 1000)]
	][v.value];
	win.refresh;
}.valueAction_(2);
pop3= PopUpMenu(win, Rect((pw+2)*3+po, 20, pw, 20))
.items_(#["Log", "Linear"])
.action_{win.refresh}.value_(0);
pop4= PopUpMenu(win, Rect((pw+2)*4+po, 20, pw, 20))
.items_(#["0.0", "0.5", "0.75", "0.9", "0.95", "0.98"])
.action_{|v|
	if(v.value>0, {
		smoothFilters= {DataSmoothing(v.item.asFloat)}.dup(board.numChannels);
	}, {
		smoothFilters= nil;
	});
}.valueAction_(3);
btn1= Button(win, Rect((pw+2)*5+po, 20, pw/2, 20)).states_(
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
btn2= Button(win, Rect((pw+2)*5.5+po, 20, pw/2, 20)).states_(
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

calculations= {
	var factor= fft.fftSize/board.currentSampleRate*0.01;
	var thetaArr= Array.new, gammaArr= Array.new;
	var thetaRange= [
		(fft.fftSize*(thetaBand[1]/board.currentSampleRate)).round.asInteger,
		(fft.fftSize*(thetaBand[2]/board.currentSampleRate)).round.asInteger
	];
	var gammaRange= [
		(fft.fftSize*(gammaBand[1]/board.currentSampleRate)).round.asInteger,
		(fft.fftSize*(gammaBand[2]/board.currentSampleRate)).round.asInteger
	];

	channels.do{|c, i|
		if(c.active and:{c.data.size>0}, {
			c.uVrms= 0;
			c.data.size.div(2).do{|i| c.uVrms= c.uVrms+pow(c.data[c.data.size-1-i], 2)};
			c.uVrms= (c.uVrms/c.data.size.div(2)).sqrt;
			c.data= fft.fft(c.data);
			if(smoothFilters.notNil, {
				c.data= smoothFilters[i].filterLog(c.data.max(0.01));
			});
			allData[i]= c.data;

			//--collect amplitudes for frequency range for selected channels
			if(thetaBand[0]==i, {
				thetaArr= thetaArr++c.data.copyRange(*thetaRange);
			});
			if(gammaBand[0]==i, {
				gammaArr= gammaArr++c.data.copyRange(*gammaRange);
			});
		});
	};

	//--calculate average energy and store in global variables
	//amended by khofsadter:
	//energyThetaAvg= thetaArr.squared.sum*factor;
	energyThetaAvg = (thetaArr.median?0).round(0.001);
	//energyGammaAvg= gammaArr.squared.sum*factor;
	energyGammaAvg = (gammaArr.median?0).round(0.001);
	//~energyTheta= energyThetaAvg.linlin(loThetaEnergy, hiThetaEnergy, 0, 1);
	~energyTheta = energyThetaAvg;
	//~energyGamma= energyGammaAvg.linlin(loGammaEnergy, hiGammaEnergy, 0, 1);
	~energyGamma = energyGammaAvg;
	//Ndef(\energyTheta).source= ~energyTheta;
	//Ndef(\energyGamma).source= ~energyGamma;
};

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
			calculations.value;
			if(animate, {usr.refresh});
		});
		(nextTime-Main.elapsedTime).max(0.001).wait;
	});
}).play(AppClock);

~openbci= board;

//to control externally:
~loThetaEnergy= loThetaEnergy;
~hiThetaEnergy= hiThetaEnergy;
~loGammaEnergy= loGammaEnergy;
~hiGammaEnergy= hiGammaEnergy;
)

//device methods:
~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;

// adjust thresholds:
~loThetaEnergy = 0;
~hiThetaEnergy = 2;
~loGammaEnergy = 0;
~hiGammaEnergy = 1;


//an example on how to record the raw EEG with extra data in txt file
(
var recorder= DataRecord(~openbci);
recorder.extra= [~energyTheta,~energyGamma];
~rec= recorder.start;
)

//post current energy values and update .extra;
r= Routine.run({inf.do{
	~rec.extra= [~energyTheta,~energyGamma];
	0.1.wait}});


r.stop;

~rec.path;

~rec.stop;
~board.stop;

~rec.path.openOS;  //open file we just recorded in text editor







