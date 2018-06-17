//fft gui example with multisliders

SerialPort.listDevices;

(
var board= Cyton;  //edit here to match you board e.g. Ganglion
var port= "/dev/tty.OpenBCI-DM00DRM0";  //edit
var win, msliders;
win= Window("fft gui example scrolling", Rect(100, 100, 640, 480)).front;
msliders= {
	MultiSliderView()
	.canFocus_(false)
	.isFilled_(true)
	.colors_(Color.black, Color.grey)
	.value_([0])
	.elasticMode_(1);
}.dup(board.numChannels);
win.layout= VLayout(*msliders);
~openbci= board.new(port, initAction:{~openbci.start});
Routine({
	var f= OpenBCIfft(~openbci, 250);
	f.start;
	inf.do{
		msliders.do{|m, i|
			m.value= f.fft[i].dbamp-1*0.1;
		};
		(1/60).wait;  //framerate
	};
}).play(AppClock);
CmdPeriod.doOnce({win.close});
)

~openbci.softReset;
~openbci.start;
