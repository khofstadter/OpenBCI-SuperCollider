//advanced sound+gui example - performing notch, bandpass and fft with scsynth

(
//~openbci= CytonSerial("/dev/tty.usbserial-DJ00DO0N", initAction: {|b| b.start});  //edit here to match you board
~openbci= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
~sequencer= OpenBCIseq(~openbci, 250);  //edit samplerate
~sequencer.start;
~openbci.warn= false;
)

(
//--settings
var bufferSize= 16384;  //fft window size (full spectrum)
var numBins= 64;  //number of bins to process and display (lower part of spectrum)
var width= 640, height= 480;
~index= 0;  //edit which channel to read from (cyton 0-7)
s.latency= 0.05;

s.waitForBoot{
	var fftArray= 0!numBins;
	var synth, bus;
	var win, usr;
	SynthDef(\fft, {|bus, loFreq= 1, hiFreq= 50, notchFreq= 50, notchRQ= 0.3, bf= 1, nf= 1, lag= 1|
		var chain;
		var sig= \data.ar(0, 0);
		sig= XFade2.ar(sig, LPF.ar(HPF.ar(sig, loFreq), hiFreq), bf*2-1);  //bandpass filter
		sig= XFade2.ar(sig, BRF.ar(sig, notchFreq, notchRQ), nf*2-1);  //notch filter for 50/60 Hz
		chain= FFT(LocalBuf(bufferSize), sig, 0.5, 1);  //fft
		Array.fill(numBins, {|i|
			var v= Demand.kr(chain>=0, 0, Unpack1FFT(chain, bufferSize, i));
			Out.kr(bus+i, v.sqrt.min(1).lag(lag));  //smooth and clip
		});
	}).load;
	bus= Bus.control(s, numBins);
	CmdPeriod.doOnce({bus.free});
	s.sync;
	~synth.free;
	~synth= Synth(\fft, [\bus, bus]);
	s.sync;
	~openbci.setSampleRate(6);  //250Hz
	~sequencer.dataAction= {|num, data, aux, stop|
		s.bind{~synth.set(\data, data[~index].linlin(-8388608, 8388607, -1, 1))};
	};
	Routine.run({
		inf.do{
			fftArray= bus.getnSynchronous(numBins);
			(1/61).wait;  //a tiny bit faster than framerate
		};
	});
	if(win.notNil, {win.close});
	win= Window("fft", Rect(10, 100, width, height), false);
	usr= UserView(win, Rect(0, 0, width, height));
	usr.animate= true;
	usr.frameRate= 60;
	usr.background= Color.black;
	usr.drawFunc= {
		Pen.fillColor= Color.white;
		numBins.do{|i|
			var freq;
			if(i%6==0, {
				freq= (s.sampleRate/bufferSize*i).asInteger;
				Pen.stringAtPoint(freq.asString, Point(i/numBins*width-4, 10));
			});
		};
		fftArray.do{|y, x|
			Pen.addRect(Rect(x/numBins*width, (1-y)*height, 1, height));
		};
		Pen.fill;
	};
	CmdPeriod.doOnce({win.close});
	win.front;
};
)

~synth.set(\notchFreq, 60)
~synth.set(\notchFreq, 50)  //europa
~synth.set(\nf, 0)  //notch filter off
~synth.set(\nf, 1)  //notch filter on
~synth.set(\notchRQ, 0.3)  //notch filter rq

~synth.set(\loFreq, 3)
~synth.set(\hiFreq, 33)
~synth.set(\bf, 0)  //bandpass filter off
~synth.set(\bf, 1)  //bandpass filter on

~synth.set(\lag, 0)
~synth.set(\lag, 1)  //the default

SerialPort.listDevices
