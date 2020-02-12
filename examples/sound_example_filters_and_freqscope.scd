//sound+freqscope example - performing notch and bandpass filtering with scsynth and play out in stereo

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
	var width= 511, height= 800;
	var win= Window("openbci", Rect(2, 10, width, height)).front;
	var scps= {|i|
		FreqScopeView(win, Rect(0, height/~openbci.numChannels*i, width, height/~openbci.numChannels-1));
	}.dup(~openbci.numChannels);
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
	CmdPeriod.doOnce({
		win.close;
		scps.do{|f| f.kill};
		bus.free; bus= nil;
	});
	win.onClose= {
		CmdPeriod.run;
	};
	{|i|
		scps[i].inBus= bus.index+i;
		scps[i].specialSynthArgs= [\fftBufSize, 8192];
		scps[i].freqMode= 1;
		scps[i].dbRange= 144;
		scps[i].active= true;

	}.dup(~openbci.numChannels);
	~mixer.free;
	~mixer= Synth(\stereoMixer, [\bus, bus, \vol, -inf]);
	~synth.free;
	~synth= Synth(\bci, [\bus, bus]);
	s.sync;
	~sequencer.dataAction= {|num, data, accel|
		s.bind{~synth.set(\data, data)};
	};
	~scopes= scps;
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

~synth.set(\amp, 0.1);  //amplify raw data signal
~synth.set(\amp, 0.01);  //(default)

~openbci.setSampleRate(6);  //250Hz (default)

~scopes.do{|f| f.freqMode= 0};  //lin
~scopes.do{|f| f.freqMode= 1};  //log (default)

~scopes.do{|f| f.dbRange= 12};
~scopes.do{|f| f.dbRange= 24};
~scopes.do{|f| f.dbRange= 36};
~scopes.do{|f| f.dbRange= 48};
~scopes.do{|f| f.dbRange= 60};
~scopes.do{|f| f.dbRange= 72};
~scopes.do{|f| f.dbRange= 84};
~scopes.do{|f| f.dbRange= 96};
~scopes.do{|f| f.dbRange= 108};
~scopes.do{|f| f.dbRange= 120};
~scopes.do{|f| f.dbRange= 132};
~scopes.do{|f| f.dbRange= 144};  //(default)

~scopes.do{|f, i| f.scope.waveColors= [Color.hsv(i/~openbci.numChannels, 0.5, 1)]};
