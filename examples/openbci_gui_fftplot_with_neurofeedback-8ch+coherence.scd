//port of OpenBCI_GUI fft plot widget, remake in supercollider by f.olofsson 2019
//MIT License, Copyright (c) 2018 OpenBCI, https://github.com/OpenBCI/OpenBCI_GUI/blob/master/LICENSE

//adapted by khofstadter to calculate same bandwith on all channels (theta below), phase coherence and example added for saving raw text file for plotting

//draw 0 - pause all drawing to save cpu
//draw 1 - only draw thresholds and average values
//draw 2 - draw everyhing including fft data

//TODO plot coherence between coherence arrays as well
//TODO too many r=Routines at bottom
//TODO refresh plotter example at end instead of redraw
//TODO refine correlation code, extendable, select locations on the top of the code
//TODO why coherence goes to 0?
//TODO ch1-8 copy&paste drawings to write more eleganlyt with a do loop.  then also more flexible if someone else want to adapt it to 4ch or other setup.
//TODO test with ganglion and daisy
//TODO (in)activate channels?

(
var activeChannels= #[0,1,2,3,4,5,6,7];
var band= Array.fill(8, { arg i; [i,4,8] }); //theta on all channels;
var loBandEnergy= 0.3, hiBandEnergy= 2;  //vertical thresholds
var bandEnergyAvg= 0 ! 8; //the current calulated averages
var phaseCalcArr= Signal.newClear(512) ! 4; //change size to 512 for longer window
//var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-09-26_11-02-46_brackets-removed-last-level-amended-last-few-minutes-removed-nfth2.0.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record (no extras i.e. Aux)
var notchFilter, bandpassFilter, smoothFilters;
var fft= DataFFT(board, 256);
var fps= 25;
var downSample= 65;  //only draw this many samples
var allData= Array.newClear(board.numChannels);  //an array of arrays with fft data
var drawModes= #[\Paused, \NoData, \DownSampl, \Complete];
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
		active: activeChannels.includes(i)
	)
}.dup(board.numChannels);

//phase calculation code
//https://scsynth.org/t/how-to-calculate-phase-synchrony/1430/24
var phaseCalcFunc = { |x, y|
	var xMean = x.mean,
	yMean = y.mean,
	momentSum = 0, xDev = 0, yDev = 0;

	x.size.do { |i|
		var xDiff = (x[i] - xMean),
		yDiff = (y[i] - yMean);
		momentSum = momentSum + (xDiff * yDiff);
		xDev = xDev + xDiff.squared;
		yDev = yDev + yDiff.squared;
	};
	xDev = (xDev / (x.size - 1)).sqrt;
	yDev = (yDev / (x.size - 1)).sqrt;  // if y has extra items, they're ignored

	momentSum / ((x.size - 1) * xDev * yDev)
};

//--window
var win= Window("fft plot widget", Rect(1500, 1500, 512, 338));
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
usr.animate= true;
usr.frameRate= fps;
usr.clearOnRefresh= true;
usr.drawFunc= {
	var uh= usr.bounds.height;
	var step= usr.bounds.width/(maxFreq+1);
	var xstep= if(drawMode==2, {step*fft.fftSize2/downSample}, {step});
	var drawLog= pop3.value==0;
	var drawMode= btn0.value;
	allData.do{|data, i|

		var energyX, energyX2, energyY, energyY2;
		//here:
		var energyYBand= 0 ! 8;

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

			// ch0:

			//--optional draw marker lines for min+max
			Pen.strokeColor= colors[0];
			energyX= band[0][1]*step;
			energyX2= band[0][2]*step;
			if(drawLog, {
				energyY= ~loBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyY2= ~loBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyYBand[0]= bandEnergyAvg[0].explin(0.1, maxAmp, uh, 0);
			}, {
				energyY= ~loBandEnergy.linlin(0, maxAmp, uh, 0);
				energyY2= ~loBandEnergy.linlin(0, maxAmp, uh, 0);
				energyYBand[0]= bandEnergyAvg[0].linlin(0, maxAmp, uh, 0);
			});
			Pen.moveTo(Point(energyX+4, energyY));
			Pen.lineTo(Point(energyX2-4, energyY));
			Pen.moveTo(Point(energyX+4, energyY2));
			Pen.lineTo(Point(energyX2-4, energyY2));
			Pen.stroke;
			Pen.width= 3;
			Pen.moveTo(Point(energyX, energyYBand[0]));
			Pen.lineTo(Point(energyX2, energyYBand[0]));
			Pen.stroke;

			//ch1
			Pen.width= 1;
			Pen.strokeColor= colors[1];
			energyX= band[1][1]*step;
			energyX2= band[1][2]*step;
			if(drawLog, {
				energyY= ~loBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyYBand[1]= bandEnergyAvg[1].explin(0.1, maxAmp, uh, 0);
			}, {
				energyY= ~loBandEnergy.linlin(0, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.linlin(0, maxAmp, uh, 0);
				energyYBand[1]= bandEnergyAvg[1].linlin(0, maxAmp, uh, 0);
			});
			Pen.moveTo(Point(energyX+4, energyY));
			Pen.lineTo(Point(energyX2-4, energyY));
			Pen.moveTo(Point(energyX+4, energyY2));
			Pen.lineTo(Point(energyX2-4, energyY2));
			Pen.stroke;
			Pen.width= 3;
			Pen.moveTo(Point(energyX, energyYBand[1]));
			Pen.lineTo(Point(energyX2, energyYBand[1]));
			Pen.stroke;

			//ch2
			Pen.width= 1;
			Pen.strokeColor= colors[2];
			energyX= band[2][1]*step;
			energyX2= band[2][2]*step;
			if(drawLog, {
				energyY= ~loBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyYBand[2]= bandEnergyAvg[2].explin(0.1, maxAmp, uh, 0);
			}, {
				energyY= ~loBandEnergy.linlin(0, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.linlin(0, maxAmp, uh, 0);
				energyYBand[2]= bandEnergyAvg[2].linlin(0, maxAmp, uh, 0);
			});
			Pen.moveTo(Point(energyX+4, energyY));
			Pen.lineTo(Point(energyX2-4, energyY));
			Pen.moveTo(Point(energyX+4, energyY2));
			Pen.lineTo(Point(energyX2-4, energyY2));
			Pen.stroke;
			Pen.width= 3;
			Pen.moveTo(Point(energyX, energyYBand[2]));
			Pen.lineTo(Point(energyX2, energyYBand[2]));
			Pen.stroke;

			//ch3
			Pen.width= 1;
			Pen.strokeColor= colors[3];
			energyX= band[3][1]*step;
			energyX2= band[3][2]*step;
			if(drawLog, {
				energyY= ~loBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyYBand[3]= bandEnergyAvg[3].explin(0.1, maxAmp, uh, 0);
			}, {
				energyY= ~loBandEnergy.linlin(0, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.linlin(0, maxAmp, uh, 0);
				energyYBand[3]= bandEnergyAvg[3].linlin(0, maxAmp, uh, 0);
			});
			Pen.moveTo(Point(energyX+4, energyY));
			Pen.lineTo(Point(energyX2-4, energyY));
			Pen.moveTo(Point(energyX+4, energyY2));
			Pen.lineTo(Point(energyX2-4, energyY2));
			Pen.stroke;
			Pen.width= 3;
			Pen.moveTo(Point(energyX, energyYBand[3]));
			Pen.lineTo(Point(energyX2, energyYBand[3]));
			Pen.stroke;

			//ch4
			Pen.width= 1;
			Pen.strokeColor= colors[4];
			energyX= band[4][1]*step;
			energyX2= band[4][2]*step;
			if(drawLog, {
				energyY= ~loBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyYBand[4]= bandEnergyAvg[4].explin(0.1, maxAmp, uh, 0);
			}, {
				energyY= ~loBandEnergy.linlin(0, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.linlin(0, maxAmp, uh, 0);
				energyYBand[4]= bandEnergyAvg[4].linlin(0, maxAmp, uh, 0);
			});
			Pen.moveTo(Point(energyX+4, energyY));
			Pen.lineTo(Point(energyX2-4, energyY));
			Pen.moveTo(Point(energyX+4, energyY2));
			Pen.lineTo(Point(energyX2-4, energyY2));
			Pen.stroke;
			Pen.width= 3;
			Pen.moveTo(Point(energyX, energyYBand[4]));
			Pen.lineTo(Point(energyX2, energyYBand[4]));
			Pen.stroke;

			//ch5
			Pen.width= 1;
			Pen.strokeColor= colors[5];
			energyX= band[5][1]*step;
			energyX2= band[5][2]*step;
			if(drawLog, {
				energyY= ~loBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyYBand[5]= bandEnergyAvg[5].explin(0.1, maxAmp, uh, 0);
			}, {
				energyY= ~loBandEnergy.linlin(0, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.linlin(0, maxAmp, uh, 0);
				energyYBand[5]= bandEnergyAvg[5].linlin(0, maxAmp, uh, 0);
			});
			Pen.moveTo(Point(energyX+4, energyY));
			Pen.lineTo(Point(energyX2-4, energyY));
			Pen.moveTo(Point(energyX+4, energyY2));
			Pen.lineTo(Point(energyX2-4, energyY2));
			Pen.stroke;
			Pen.width= 3;
			Pen.moveTo(Point(energyX, energyYBand[5]));
			Pen.lineTo(Point(energyX2, energyYBand[5]));
			Pen.stroke;

			//ch6
			Pen.width= 1;
			Pen.strokeColor= colors[6];
			energyX= band[6][1]*step;
			energyX2= band[6][2]*step;
			if(drawLog, {
				energyY= ~loBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyYBand[6]= bandEnergyAvg[6].explin(0.1, maxAmp, uh, 0);
			}, {
				energyY= ~loBandEnergy.linlin(0, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.linlin(0, maxAmp, uh, 0);
				energyYBand[6]= bandEnergyAvg[6].linlin(0, maxAmp, uh, 0);
			});
			Pen.moveTo(Point(energyX+4, energyY));
			Pen.lineTo(Point(energyX2-4, energyY));
			Pen.moveTo(Point(energyX+4, energyY2));
			Pen.lineTo(Point(energyX2-4, energyY2));
			Pen.stroke;
			Pen.width= 3;
			Pen.moveTo(Point(energyX, energyYBand[6]));
			Pen.lineTo(Point(energyX2, energyYBand[6]));
			Pen.stroke;

			//ch7
			Pen.width= 1;
			Pen.strokeColor= colors[7];
			energyX= band[7][1]*step;
			energyX2= band[7][2]*step;
			if(drawLog, {
				energyY= ~loBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.explin(0.1, maxAmp, uh, 0);
				energyYBand[7]= bandEnergyAvg[7].explin(0.1, maxAmp, uh, 0);
			}, {
				energyY= ~loBandEnergy.linlin(0, maxAmp, uh, 0);
				energyY2= ~hiBandEnergy.linlin(0, maxAmp, uh, 0);
				energyYBand[7]= bandEnergyAvg[7].linlin(0, maxAmp, uh, 0);
			});
			Pen.moveTo(Point(energyX+4, energyY));
			Pen.lineTo(Point(energyX2-4, energyY));
			Pen.moveTo(Point(energyX+4, energyY2));
			Pen.lineTo(Point(energyX2-4, energyY2));
			Pen.stroke;
			Pen.width= 3;
			Pen.moveTo(Point(energyX, energyYBand[7]));
			Pen.lineTo(Point(energyX2, energyYBand[7]));
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
		usr.animate= false;
	}, {
		usr.animate= true;
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
		notchFilter= DataFilterNotch(DataFilterNotch.keys[v.value-1]);
	}, {
		notchFilter= nil;
	});
}.valueAction_(1);
btn2= Button(win, Rect((pw+2)*5.5+po, 20, pw/2, 20)).states_(
	[["Off"]]++DataFilterBandpass.keys.collect{|x| [x.asString]}
).action_{|v|
	if(v.value>0, {
		bandpassFilter= DataFilterBandpass(DataFilterBandpass.keys[v.value-1]);
	}, {
		bandpassFilter= nil;
	});
}.valueAction_(1);
win.view.children.reject{|v| v==usr}.do{|v| v.resize_(3).font_(f2)};

//--update data in an independent routine
Routine.run({
	inf.do{
		var factor= fft.fftSize/board.currentSampleRate*0.01;

		//here:
		var bandArr= Array.new ! 8;

		var bandRange0= [
			(fft.fftSize*(band[0][1]/board.currentSampleRate)).round.asInteger,
			(fft.fftSize*(band[0][2]/board.currentSampleRate)).round.asInteger
		];
		var bandRange1= [
			(fft.fftSize*(band[1][1]/board.currentSampleRate)).round.asInteger,
			(fft.fftSize*(band[1][2]/board.currentSampleRate)).round.asInteger
		];

		var bandRange2= [
			(fft.fftSize*(band[2][1]/board.currentSampleRate)).round.asInteger,
			(fft.fftSize*(band[2][2]/board.currentSampleRate)).round.asInteger
		];

		var bandRange3= [
			(fft.fftSize*(band[3][1]/board.currentSampleRate)).round.asInteger,
			(fft.fftSize*(band[3][2]/board.currentSampleRate)).round.asInteger
		];

		var bandRange4= [
			(fft.fftSize*(band[4][1]/board.currentSampleRate)).round.asInteger,
			(fft.fftSize*(band[4][2]/board.currentSampleRate)).round.asInteger
		];
		var bandRange5= [
			(fft.fftSize*(band[5][1]/board.currentSampleRate)).round.asInteger,
			(fft.fftSize*(band[5][2]/board.currentSampleRate)).round.asInteger
		];
		var bandRange6= [
			(fft.fftSize*(band[6][1]/board.currentSampleRate)).round.asInteger,
			(fft.fftSize*(band[6][2]/board.currentSampleRate)).round.asInteger
		];
		var bandRange7= [
			(fft.fftSize*(band[7][1]/board.currentSampleRate)).round.asInteger,
			(fft.fftSize*(band[7][2]/board.currentSampleRate)).round.asInteger
		];


		channels.do{|c, i|
			var data;
			if(c.active, {
				data= board.buffer[i];
				if(notchFilter.notNil, {
					data= notchFilter.filter(data);
				});
				if(bandpassFilter.notNil, {
					data= bandpassFilter.filter(data);
				});
				data= fft.fft(data);
				if(smoothFilters.notNil, {
					data= smoothFilters[i].filter(data);
				});
				allData[i]= data;

				//here:
				//--collect amplitudes for frequency range for selected channels
				if(band[0][0]==i, {
					bandArr[0]= bandArr[0]++data.copyRange(*bandRange0);
				});
				if(band[1][0]==i, {
					bandArr[1]= bandArr[1]++data.copyRange(*bandRange1);
				});
				if(band[2][0]==i, {
					bandArr[2]= bandArr[2]++data.copyRange(*bandRange2);
				});
				if(band[3][0]==i, {
					bandArr[3]= bandArr[3]++data.copyRange(*bandRange3);
				});
				if(band[4][0]==i, {
					bandArr[4]= bandArr[4]++data.copyRange(*bandRange4);
				});
				if(band[5][0]==i, {
					bandArr[5]= bandArr[5]++data.copyRange(*bandRange5);
				});
				if(band[6][0]==i, {
					bandArr[6]= bandArr[6]++data.copyRange(*bandRange6);
				});
				if(band[7][0]==i, {
					bandArr[7]= bandArr[7]++data.copyRange(*bandRange7);
				});
			});
		};

		bandEnergyAvg[0]= bandArr[0].median.round(0.001);
		bandEnergyAvg[1]= bandArr[1].median.round(0.001);
		bandEnergyAvg[2]= bandArr[2].median.round(0.001);
		bandEnergyAvg[3]= bandArr[3].median.round(0.001);
		bandEnergyAvg[4]= bandArr[4].median.round(0.001);
		bandEnergyAvg[5]= bandArr[5].median.round(0.001);
		bandEnergyAvg[6]= bandArr[6].median.round(0.001);
		bandEnergyAvg[7]= bandArr[7].median.round(0.001);
		~bandEnergyAvg[0]= bandEnergyAvg[0]; //ch1
		~bandEnergyAvg[1]= bandEnergyAvg[1]; //ch2
		~bandEnergyAvg[2]= bandEnergyAvg[2]; //ch3
		~bandEnergyAvg[3]= bandEnergyAvg[3]; //ch4
		~bandEnergyAvg[4]= bandEnergyAvg[4]; //ch5
		~bandEnergyAvg[5]= bandEnergyAvg[5]; //ch6
		~bandEnergyAvg[6]= bandEnergyAvg[6]; //ch7
		~bandEnergyAvg[7]= bandEnergyAvg[7]; //ch8

		phaseCalcArr[0]= phaseCalcArr[0].rotate(-1);
		phaseCalcArr[1]= phaseCalcArr[1].rotate(-1);
		phaseCalcArr[2]= phaseCalcArr[2].rotate(-1);
		//phaseCalcArr[3]= phaseCalcArr[3].rotate(-1);
		phaseCalcArr[0][phaseCalcArr[0].size-1]= ~bandEnergyAvg[2]; //ch3
		phaseCalcArr[1][phaseCalcArr[1].size-1]= ~bandEnergyAvg[3]; //ch4
		phaseCalcArr[2][phaseCalcArr[2].size-1]= ~bandEnergyAvg[6]; //ch7
		//phaseCalcArr[3][phaseCalcArr[3].size-1]= ~bandEnergyAvg[7]; //ch8

		//two phase coherence calculations:
		~phaseCalcFuncVal[0]= (phaseCalcFunc.(phaseCalcArr[0], phaseCalcArr[1])).round(0.01);
		~phaseCalcFuncVal[1]= (phaseCalcFunc.(phaseCalcArr[0], phaseCalcArr[2])).round(0.01);

		~phaseCalcArr[0]= phaseCalcArr[0];
		~phaseCalcArr[1]= phaseCalcArr[1];
		~phaseCalcArr[2]= phaseCalcArr[2];
		//~phaseCalcArr[3]= phaseCalcArr[3];

		(1/fps).wait;
	};
}, clock:AppClock);

~bandEnergyAvg= 0 ! 8;
~phaseCalcArr= 0 ! 4;
~openbci= board;
~loBandEnergy= loBandEnergy;
~hiBandEnergy= hiBandEnergy;
~phaseCalcFuncVal= 0 ! 2;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;

~loBandEnergy = 0;
~hiBandEnergy = 1.5;

//post current energy values
r= Routine.run({inf.do{[~bandEnergyAvg.postln]; 0.25.wait}});
r.stop;

//plot ~phaseCalcFuncVal
(
var data = [~phaseCalcArr[0],~phaseCalcArr[1],~phaseCalcFuncVal[0]!512,~phaseCalcArr[2],~phaseCalcFuncVal[1]!512];
var plotter = Plotter("plotter",Rect(5,5,630,405));
plotter.plotMode = \plines;
plotter.value_(data);
~phaseCalcFuncVal;
);

//post current energy values
r= Routine.run({inf.do{[~phaseCalcFuncVal.postln]; 0.25.wait}});
r.stop;


(
//record raw EEG and extra data into a text file
~recorder= DataRecord(~openbci);
~rec= ~recorder.start;

//update DataRecord extra
r= Routine.run({inf.do{
	~rec.extra= [~bandEnergyAvg[0],~bandEnergyAvg[1],~bandEnergyAvg[2],~bandEnergyAvg[3],~bandEnergyAvg[4],~bandEnergyAvg[5],~bandEnergyAvg[6],~bandEnergyAvg[7],~hiBandEnergy,~phaseCalcFuncVal[0],~phaseCalcFuncVal[1]];
	0.25.wait}});
//r.stop;
)