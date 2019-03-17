//fft gui example with multisliders

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b| b.start});
var win, msliders;
win= Window("fft gui example multislider", Rect(100, 100, 640, 640)).front;
msliders= {
	MultiSliderView()
	.canFocus_(false)
	.isFilled_(true)
	.colors_(Color.black, Color.grey)
	.value_([0])
	.elasticMode_(1);
}.dup(board.numChannels);
win.layout= VLayout(*msliders);
Routine({
	var f= OpenBCIfft(board, 256);
	f.start;
	inf.do{
		msliders.do{|m, i|
			m.value= f.fft(i).explin(0.1, 200, 0, 1);  //0.1-200 uV
		};
		(1/60).wait;  //framerate
	};
}).play(AppClock);
CmdPeriod.doOnce({win.close});
~openbci= board;
)

~br= DataFilterNotch('50');
~openbci.addFilter(~br);
~bp= DataFilterBandpass('5-50');
~openbci.addFilter(~bp);
~openbci.filters;
~openbci.removeFilter(~br);

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
