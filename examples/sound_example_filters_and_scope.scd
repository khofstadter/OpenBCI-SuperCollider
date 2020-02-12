//sound+scope example - performing notch and bandpass filtering with scsynth and play out in stereo

(
~openbci= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//~openbci= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//~openbci= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//~openbci= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//DataRecord(~openbci).start;  //uncomment to record
~sequencer= DataSequencer(~openbci, 1000, true, false);
~sequencer.start;

s.latency= 0.05;
s.waitForBoot{
	var bus;
	SynthDef(\bci, {|bus, loFreq= 1, hiFreq= 50, notchFreq= 50, notchRQ= 0.3, bf= 1, nf= 1, lag= 0, amp= 0.01|
		var sig= K2A.ar(\data.kr(0!~openbci.numChannels, lag))*amp;
		sig= sig*\on.kr(1!~openbci.numChannels, 0.1);
		sig= Select.ar(bf, [sig, LPF.ar(HPF.ar(sig, loFreq), hiFreq)]);  //bandpass filter
		sig= Select.ar(nf, [sig, BRF.ar(sig, notchFreq, notchRQ)]);  //notch filter for 50/60 Hz
		Out.ar(bus, sig);
	}).add;
	SynthDef(\stereoMixer, {|out= 0, bus, vol= 0|
		var sig= In.ar(bus, ~openbci.numChannels);
		//sig= SinOsc.ar((1..~openbci.numChannels)*100+200, 0, sig);  //uncomment to modulate
		sig= Splay.ar(sig);
		Out.ar(out, sig*vol.dbamp.lag);
	}).add;
	bus= Bus.audio(s, ~openbci.numChannels);
	s.sync;
	~scope= s.scope(~openbci.numChannels, bus.index, 4096, 0.25);
	~scope.size= 400;
	CmdPeriod.doOnce({
		bus.free; bus= nil;
		~scope.window.close;
	});
	~mixer.free;
	~mixer= Synth(\stereoMixer, [\bus, bus, \vol, -inf]);
	~synth.free;
	~synth= Synth(\bci, [\bus, bus]);
	s.sync;
	~sequencer.dataAction= {|num, data, accel|
		s.bind{~synth.set(\data, data)};
	};
};
)

~mixer.set(\vol, -20);  //turn up volume - carefully
~mixer.set(\vol, -10);
~mixer.set(\vol, -3);  //note: might be loud

~synth.set(\on, #[1, 1, 0, 0, 0, 0, 0, 0]);  //mute some channels
~synth.set(\on, #[1, 1, 1, 1, 1, 1, 1, 1]);  //unmute all (default)

~synth.set(\nf, 0);  //notch filter off
~synth.set(\nf, 1);  //notch filter on (default)
~synth.set(\notchFreq, 60);  //60Hz
~synth.set(\notchFreq, 50);  //50Hz (default)
~synth.set(\notchRQ, 1);
~synth.set(\notchFreq, 50, \notchRQ, 0.3);  //notch filter rq (default)

~synth.set(\bf, 0);  //bandpass filter off
~synth.set(\bf, 1);  //bandpass filter on (default)
~synth.set(\loFreq, 3);
~synth.set(\hiFreq, 33);
~synth.set(\loFreq, 10);
~synth.set(\hiFreq, 100);
~synth.set(\loFreq, 1, \hiFreq, 50);  //(default)

~synth.set(\lag, 0.01)  //signal smoothing (lowpass)
~synth.set(\lag, 0.1)
~synth.set(\lag, 1)
~synth.set(\lag, 0)  //off (default)

~synth.set(\amp, 0.02);  //amplify raw data signal
~synth.set(\amp, 0.01);  //(default)

~openbci.setSampleRate(6);  //250Hz (default)
