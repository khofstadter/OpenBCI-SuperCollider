//simple sound example - just some sines

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b| b.start});
var sequencer= OpenBCIseq(board);
sequencer.start;
board.warn= false;
s.latency= 0.05;
s.waitForBoot{
	Ndef(\sines, {|t_trig= 0|
		var f= \freq.kr(400!board.numChannels);
		Timer.kr(t_trig).poll;  //post time between updates in seconds
		Splay.ar(SinOsc.ar(f, 0, 1/board.numChannels));
	}).play(fadeTime: 3);
	sequencer.dataAction= {|num, data, aux, stop|  //try to exchange with board.dataAction and compare timing
		Ndef(\sines).set(\freq, data.linexp(-8388608, 8388607, 200, 2000), \t_trig, 1);
	};
};
~openbci= board;
)

~openbci.currentSampleRate
~openbci.setSampleRate(4)  //with wifi shield one can increase the samplerate
~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
Ndef(\sines).clear(1);
