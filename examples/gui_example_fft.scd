//fft gui example with multisliders

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
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
	inf.do{
		var buffer= board.buffer.deepCopy;
		if(~notchFilter.notNil, {
			buffer= ~notchFilter.filter(buffer, 5000, 5750);
		});
		if(~bandpassFilter.notNil, {
			buffer= ~bandpassFilter.filter(buffer, 5000, 5750);
		});
		msliders.do{|m, i|
			m.value= f.fft(buffer, i).explin(0.1, 200, 0, 1);  //0.1-200 uV
		};
		(1/30).wait;  //framerate
	};
}).play(AppClock);
CmdPeriod.doOnce({win.close});
~openbci= board;
)

~notchFilter= DataFilterNotch('50');
~notchFilter= nil;
~bandpassFilter= DataFilterBandpass('5-50');
~bandpassFilter= DataFilterBandpass('7-13');
~bandpassFilter= nil;


~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
