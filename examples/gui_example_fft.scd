//fft gui example with multisliders

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var f= DataFFT(board, 256);
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
	inf.do{
		board.buffer.do{|data, i|
			if(~notchFilter.notNil, {
				data= ~notchFilter.filter(data);
			});
			if(~bandpassFilter.notNil, {
				data= ~bandpassFilter.filter(data);
			});
			msliders[i].value= f.fft(data).explin(0.1, 200, 0, 1);  //0.1-200 uV
		};
		(1/30).wait;  //framerate
	};
}).play(AppClock);
CmdPeriod.doOnce({win.close});
~openbci= board;
)

~notchFilter= DataFilterNotch('50');
~notchFilter= DataFilterNotch('60');
~notchFilter= nil;
~bandpassFilter= DataFilterBandpass('1-50');
~bandpassFilter= DataFilterBandpass('5-50');
~bandpassFilter= DataFilterBandpass('15-50');
~bandpassFilter= DataFilterBandpass('7-13');
~bandpassFilter= nil;


~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
