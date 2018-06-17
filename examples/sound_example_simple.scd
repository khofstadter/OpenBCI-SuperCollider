//simple sound example - just some sines

SerialPort.listDevices;

(
var board= Cyton;  //edit here to match you board e.g. Ganglion
var port= "/dev/tty.OpenBCI-DM00DRM0";  //edit
~openbci= board.new(port, initAction:{~openbci.start});
s.latency= 0.05;
s.waitForBoot{
	Ndef(\sines, {
		var f= \freq.kr(400!board.numChannels);
		Splay.ar(SinOsc.ar(f, 0, 1/board.numChannels));
	}).play(fadeTime: 3);
	~openbci.dataAction= {|num, data, aux, stop|
		Ndef(\sines).set(\freq, data.linexp(-8388607, 8388607, 200, 2000));
	};
};
)

~openbci.softReset;
~openbci.start;
