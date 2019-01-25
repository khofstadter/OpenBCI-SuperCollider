//simple sound example - just some sines

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match you board
//var board= CytonWifi(NetAddr("192.168.1.103", 13999), initAction: {|b| b.start});
s.latency= 0.05;
s.waitForBoot{
	Ndef(\sines, {
		var f= \freq.kr(400!board.numChannels);
		Splay.ar(SinOsc.ar(f, 0, 1/board.numChannels));
	}).play(fadeTime: 3);
	board.dataAction= {|num, data, aux, stop|
		Ndef(\sines).set(\freq, data.linexp(-8388607, 8388607, 200, 2000));
	};
};
~openbci= board;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
Ndef(\sines).clear(1);
