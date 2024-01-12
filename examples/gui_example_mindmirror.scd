//gui example after Mind Mirror v2 with 14 channels
//meassure at T5-O1 and T6-O2
//https://www.richardmudhar.com/blog/2017/05/mind-mirror-reverse-engineering/

(
var activeChannels= #[0, 1];  //only two - left and right side - T5-O1 and T6-O2
var filterHum= '50';  //filter out mains (in Hz - can be '50' or '60')
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record

var frequencyBands= #[0.75, 1.5, 3, 4.5, 6, 7.5, 9, 10.5, 12.5, 15, 19, 24, 30, 38, 48];  //last freq only visible with outline
var colors= [
	#[0, 1, 2] -> Color.new255(159, 49, 235),  //0.75, 1.5, 3
	#[3, 4, 5] -> Color.new255(112, 139, 230),  //4.5, 6, 7.5
	#[6, 7, 8] -> Color.new255(40, 138, 42),  //9, 10.5, 12.5
	#[9] -> Color.new255(247, 243, 81),  //15
	#[10] -> Color.new255(243, 178, 54),  //19
	#[11] -> Color.new255(241, 112, 40),  //24
	#[12, 13] -> Color.new255(232, 72, 40),  //30, 38
];
var f0= Font("Helvetiva", 12, italic:true);
var bandData= 0.dup(activeChannels.size).dup(frequencyBands.size);
var sequencer= DataSequencer(board, 1000, true, false);
var notchFilters= {
	DataFilterNotch(filterHum, board.currentSampleRate, board.bufferSize);
}.dup(activeChannels.size);
var mindSynth;

//--window
var win= Window("gui example mind mirror", Rect(10, 100, 600, 400));
win.background= Color.black;
win.view.minSize= Size(260, 144);
win.front;

win.onClose= {
	board.stop;
	mindSynth.free;
	OSCdef(\mind).free;
};
CmdPeriod.doOnce({
	mindSynth= nil;
	win.close;
});

win.drawFunc= {
	var bandPoints;
	var width2= win.bounds.width*0.5;
	var height= win.bounds.height;
	var hh= height/15;
	var verticalGap= hh*0.2;
	var barHeight= hh-verticalGap;
	var horizontalGap= 30;
	var borderGap= 20;
	var tw= horizontalGap*2;

	Pen.translate(width2, height-(verticalGap*0.5));
	Pen.fillColor= Color.white;
	5.do{|i|
		var uV= (i+1/5*~maxuV);
		var x= uV.linlin(0, ~maxuV, horizontalGap, width2-borderGap);
		var pnt= Point(0-x, -0.5*barHeight);
		Pen.stringCenteredIn(uV.asString, Rect.aboutPoint(pnt, tw, hh), f0);
		pnt= Point(x, -0.5*barHeight);
		Pen.stringCenteredIn(uV.asString, Rect.aboutPoint(pnt, tw, hh), f0);
	};

	Pen.translate(0, 0-hh);
	bandPoints= bandData.collect{|band, i|
		var left= band.wrapAt(0);
		var right= band.wrapAt(1);
		var leftX= 0-left.linlin(0, ~maxuV, 0, width2-borderGap-horizontalGap);
		var rightX= right.linlin(0, ~maxuV, 0, width2-borderGap-horizontalGap);
		var y= 0-(hh*i);
		[Point(leftX, y), left>~maxuV, Point(rightX, y), right>~maxuV];
	};
	bandPoints.drop(-1).do{|pnts, i|
		var y= pnts[0].y;
		var str= frequencyBands[i].asString;
		Pen.fillColor= colors.detect{|a| a.key.includes(i)}.value;
		Pen.addRect(Rect(0-horizontalGap, y, pnts[0].x, 0-barHeight));
		Pen.addRect(Rect(horizontalGap, y, pnts[2].x, 0-barHeight));
		Pen.fill;
		Pen.fillColor= Color.white;
		Pen.stringCenteredIn(str, Rect.aboutPoint(Point(0, -0.5*barHeight+y), tw, hh), f0);
		if(pnts[1], {Pen.fillRect(Rect(0-width2, y, borderGap, 0-barHeight))});
		if(pnts[3], {Pen.fillRect(Rect(width2, y, 0-borderGap, 0-barHeight))});
	};

	if(~outline, {
		Pen.strokeColor= Color.white;
		Pen.width= 5;
		Pen.moveTo(Point(0-horizontalGap, 0));
		bandPoints.do{|pnts, i|
			var y= pnts[0].y;
			Pen.lineTo(Point(pnts[0].x-horizontalGap, y));
		};
		Pen.moveTo(Point(horizontalGap, 0));
		bandPoints.do{|pnts, i|
			var y= pnts[2].y;
			Pen.lineTo(Point(pnts[2].x+horizontalGap, y));
		};
		Pen.stroke;
	});
};

~maxuV= 20;
~outline= false;
sequencer.start;
//board.noiseAmp= 0;  //for debugging

if(activeChannels.size!=2, {
	"The array activeChannels can only contain two indices.".error;
}, {
	sequencer.dataAction= {|num, data, acc|
		var d;
		if(mindSynth.notNil, {
			d= data[activeChannels];
			d.do{|x, i| notchFilters[i].filterN(x)};
			s.bind{mindSynth.set(\data, d)};
		});
	};
});

Routine({
	var nextTime;
	while({win.isClosed.not}, {
		nextTime= Main.elapsedTime+(1/60);
		win.refresh;
		(nextTime-Main.elapsedTime).max(0.001).wait;
	});
}).play(AppClock);

s.latency= 0.05;
s.waitForBoot{
	SynthDef(\mind, {
		var trg= Impulse.kr(15);
		var data= \data.kr(#[0, 0]);
		var left= K2A.ar(data[0]);
		var right= K2A.ar(data[1]);
		var rq= frequencyBands.lincurve(0, 38, 1, 0.1, -3);  //TODO tune
		3.do{
			left= BPF.ar(left, frequencyBands, rq);
			right= BPF.ar(right, frequencyBands, rq);
		};
		left= PeakFollower.ar(left, 0.99999);
		right= PeakFollower.ar(right, 0.99999);
		SendReply.kr(trg, "/mind", left++right);
	}).add;
	s.sync;
	mindSynth= Synth(\mind);
	OSCdef(\mind, {|msg|
		frequencyBands.do{|f, i|
			bandData[i]= [msg[3+i], msg[3+frequencyBands.size+i]]/2.sqrt;
		};
	}, \mind, s.addr);
};

~openbci= board;
)


~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;

~maxuV= 3;
~maxuV= 30;
~maxuV= 100;
~maxuV= 15;
~maxuV= 20;  //default

~outline= true;  //turn on white lines
~outline= false;
