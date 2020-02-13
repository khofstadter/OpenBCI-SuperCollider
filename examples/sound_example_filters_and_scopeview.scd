//advanced sound+freqscope example - using ScopeView and custom synthdef instead of FreqScopeView

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
	var bus, buffers;
	var fftSize= 8192*2*2;
	var binSize= s.sampleRate/fftSize;
	var width= 511, height= 800, scpsHeight= height-20;
	var win= Window("openbci", Rect(2, 100, width, height)).front;
	var scps= {|i|
		ScopeView(win, Rect(0, scpsHeight/~openbci.numChannels*i, width, scpsHeight/~openbci.numChannels-1));
	}.dup(~openbci.numChannels);
	StaticText(win, Rect(0, scpsHeight, 50, 20)).string_(""++binSize.round(0.1));
	Array.geom(12, 1, 1.1).normalize.linlin(0, 1, 0.07, 0.9).do{|x|
		StaticText(win, Rect.aboutPoint(Point(width*x, scpsHeight+10), 50, 20)).align_(\center)
		.string_(""++(x.linexp(0, 1, binSize, s.sampleRate/2).round(0.1)));
	};
	StaticText(win, Rect(width-50, scpsHeight, 50, 20)).align_(\right).string_("Hz");

	//based on system_freqScope1_shm in FreqScopeView but this one can be customisable
	SynthDef(\bciscope_log, {|in= 0, fftBufSize= 8192, scopebufnum, rate= 4, dbFactor= 0.02, scale= 1, smear= 4|
		var phase= 1-(rate*fftBufSize.reciprocal);
		var signal, chain, phasor, halfSamples, mul;
		var fftbufnum= LocalBuf(fftBufSize, 1);
		mul= 0.00285;
		halfSamples= BufSamples.ir(fftbufnum)*0.5;
		signal= In.ar(in, 1)*scale;
		//signal= SinOsc.ar(12);  //debug test signal
		chain= FFT(fftbufnum, signal, hop: 0.75, wintype: 1);
		//chain= PV_MagSmear(chain, smear);  //smooth adjacent bins
		//chain= PV_BrickWall(PV_BrickWall(chain, 0.0025), -0.99);  //example brickwall
		phasor= halfSamples.pow(LFSaw.ar(rate/BufDur.ir(fftbufnum), phase, 0.5, 0.5))*2;
		phasor= phasor.round(2);
		ScopeOut2.ar(
			(BufRd.ar(1, fftbufnum, phasor, 1, 1)*mul).ampdb*dbFactor+1,
			scopebufnum,
			fftBufSize/rate
		);
	}, #[\kr, \ir, \ir, \ir, \kr, \kr, \kr]).add;
	SynthDef(\bci, {|bus, loFreq= 1, hiFreq= 50, notchFreq= 50, notchRQ= 0.3, bf= 1, nf= 1, lag= 0, amp= 0.001|
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
	buffers= {ScopeBuffer.alloc(s, 1)}.dup(~openbci.numChannels);
	s.sync;
	CmdPeriod.doOnce({
		win.close;
		scps.do{|f| f.stop};
		bus.free; bus= nil;
		buffers.do{|b| b.free}; buffers= nil;
	});
	win.onClose= {
		CmdPeriod.run;
	};
	scps.do{|f, i|
		f.server= s;
		f.bufnum= buffers[i].bufnum;
		f.fill= false;
		f.start;
	};
	~scopeSynths.do{|x| x.free};
	~scopeSynths= {|i|
		Synth(\bciscope_log, [\in, bus.index+i, \fftBufSize, fftSize, \scopebufnum, buffers[i].bufnum]);
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

//activate magsmear in synthdef for this to work
// ~scopeSynths.do{|x| x.set(\smear, 12)}  //bins to average on each side
// ~scopeSynths.do{|x| x.set(\smear, 2)}
// ~scopeSynths.do{|x| x.set(\smear, 1)}
// ~scopeSynths.do{|x| x.set(\smear, 4)}  //(default)

~scopeSynths.do{|x| x.set(\scale, 1)}  //set amplitude independent of audio output
~scopeSynths.do{|x| x.set(\scale, 1)}  //(default)

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

~synth.set(\amp, 0.005);  //amplify raw data signal
~synth.set(\amp, 0.0001);  //(default)

~openbci.setSampleRate(6);  //250Hz (default)

~scopes.do{|f, i| f.waveColors= [Color.hsv(i/~openbci.numChannels, 0.5, 1)]};
