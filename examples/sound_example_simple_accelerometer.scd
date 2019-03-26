//simple sound accelerometer example- just some sines

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
var sequencer= DataSequencer(board, 100, false, true);
sequencer.start;
board.warn= false;
s.latency= 0.05;
s.waitForBoot{
	Ndef(\sines3, {|t_trig= 0|
		var f= \freq.kr(400!3, 1/25);
		Timer.kr(t_trig).poll;  //post time between updates in seconds
		LeakDC.ar(Splay.ar(SinOsc.ar(f, 0, 1/3)));
	}).play(fadeTime: 3);
	sequencer.accelAction= {|xyz|
		Ndef(\sines3).set(\freq, xyz.linexp(-4, 4, 100, 10000), \t_trig, 1);
	};
};
~openbci= board;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
Ndef(\sines3).clear(1);
