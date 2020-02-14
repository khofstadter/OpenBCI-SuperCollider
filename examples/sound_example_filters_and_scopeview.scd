//advanced sound+freqscope example - using ScopeView and custom synthdef instead of FreqScopeView
//note: this is more like a template showing how to get and use the bci data in scsynth

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
	var signalBus, scopeBuffer;
	var zoom= 256;
	var fftSize= 32768;
	var binSize= s.sampleRate/fftSize;
	var width= 511, height= 800, scpsHeight= height-20;
	var win= Window("openbci", Rect(2, 100, width, height)).front;
	var scp= ScopeView(win, Rect(0, 0, width, scpsHeight));
	StaticText(win, Rect(0, scpsHeight, 50, 20)).string_(""++binSize.round(0.1));
	Array.geom(10, 1, 1.05).normalize.linlin(0, 1, 0.075, 0.9).do{|x|
		StaticText(win, Rect.aboutPoint(Point(width*x, scpsHeight+10), 50, 20))
		.string_(""++((x.linlin(0, 1, binSize, s.sampleRate/2)/zoom).round(0.1)))
		.align_(\center);
	};
	StaticText(win, Rect(width-50, scpsHeight, 50, 20)).align_(\right).string_("Hz");

	//based on system_freqScope0_shm in FreqScopeView but this one can be customized
	SynthDef(\bciscope, {|bus= 0, scopebufnum|
		var phase= 1-(zoom*fftSize.reciprocal);
		var signal, chain, phasor, numSamples;
		var fftbufnum= {LocalBuf(fftSize, 1)}!~openbci.numChannels;
		numSamples= (fftSize-2)*0.5;
		signal= In.ar(bus, ~openbci.numChannels);
		chain= FFT(fftbufnum, signal, hop:0.125, wintype:1);
		chain.do{|c| c.pvcollect(zoom/2, {|mag, phase, index| mag*mag*0.001})};

		//--example brickwall from 8 to 12 Hz
		//chain= PV_BrickWall(PV_BrickWall(chain, 8/(SampleRate.ir/2)), -1+(12/(SampleRate.ir/2)));

		phasor= LFSaw.ar(zoom/(fftSize/SampleRate.ir), phase, numSamples, numSamples+2).round(2);
		ScopeOut2.ar(
			BufRd.ar(1, fftbufnum, phasor/zoom, 1, 0).abs.linlin(0, 5000, -1, 1, \min),
			scopebufnum,
			fftSize/zoom
		);
	}, #[\kr, \ir]).add;

	SynthDef(\bci, {|bus, loFreq= 1, hiFreq= 50, notchFreq= 50, notchRQ= 0.3, bf= 1, nf= 1, amp= 0.01|
		var sig= K2A.ar(\data.kr(0!~openbci.numChannels))*amp;
		sig= sig*\on.kr(1!~openbci.numChannels, 0.1);
		sig= Select.ar(bf, [sig, LPF.ar(HPF.ar(sig, loFreq), hiFreq)]);  //bandpass filter
		sig= Select.ar(nf, [sig, BRF.ar(sig, notchFreq, notchRQ)]);  //notch filter for 50/60 Hz
		//sig= SinOsc.ar((7..0)+26.8, 0, 0.25);  //debug test
		Out.ar(bus, sig);
	}).add;
	SynthDef(\stereoMixer, {|out= 0, bus, vol= 0|
		var sig= In.ar(bus, ~openbci.numChannels);
		//sig= SinOsc.ar((1..~openbci.numChannels)*100+200, 0, sig);  //uncomment to modulate
		sig= Splay.ar(sig);
		Out.ar(out, sig*vol.dbamp.lag);
	}).add;
	signalBus= Bus.audio(s, ~openbci.numChannels);
	scopeBuffer= ScopeBuffer.alloc(s, ~openbci.numChannels);
	s.sync;
	CmdPeriod.doOnce({
		win.close;
		scp.stop;
		signalBus.free; signalBus= nil;
		scopeBuffer.free; scopeBuffer= nil;
	});
	win.onClose= {
		CmdPeriod.run;
	};
	scp.server= s;
	scp.bufnum= scopeBuffer.bufnum;
	scp.fill= false;
	scp.start;
	s.sync;
	~scopeSynth.free;
	~scopeSynth= Synth(\bciscope, [\bus, signalBus, \scopebufnum, scopeBuffer.bufnum]);
	~mixer.free;
	~mixer= Synth(\stereoMixer, [\bus, signalBus, \vol, -inf]);
	~synth.free;
	~synth= Synth(\bci, [\bus, signalBus]);
	s.sync;
	~sequencer.dataAction= {|num, data, accel|
		s.bind{~synth.set(\data, data)};
	};
	~scope= scp;
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
~synth.set(\loFreq, 10);
~synth.set(\hiFreq, 33);
~synth.set(\loFreq, 20);
~synth.set(\hiFreq, 100);
~synth.set(\loFreq, 1, \hiFreq, 50);  //(default)

~synth.set(\amp, 0.02);  //amplify raw data signal
~synth.set(\amp, 0.01);  //(default)

~openbci.setSampleRate(6);  //250Hz (default)

~scope.waveColors= {|i| Color.hsv(i/~openbci.numChannels, 0.5, 1)}.dup(~openbci.numChannels);
~scope.yZoom= 5;
~scope.yZoom= 1;  //(default)
