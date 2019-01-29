//advanced sound+gui example - performing notch, bandpass and fft with scsynth

//if "ERROR: Primitive '_GetHostByName' failed." then press cmd+. wait a few seconds and try again

(
//--settings
var index= 0;  //edit which channel to read from (cyton 0-7)
var ip= "192.168.1.100";  //edit to match laptop ip
var bufferSize= 16384;  //fft window size (full spectrum)
var bins= 64;  //number of bins to process and display (lower part of spectrum)
var width= 640, height= 480;
s.latency= 0.05;

s.waitForBoot{
	var fftArray= 0!bins;
	var board, synth, bus, task;
	var win, usr;
	SynthDef(\fft, {|bus, loFreq= 1, hiFreq= 50, notchFreq= 60, notchRQ= 0.5, lag= 1|
		var chain;
		var sig= \data.ar([0], 0);
		sig= LPF.ar(HPF.ar(sig, loFreq), hiFreq);  //bandpass filter
		sig= BRF.ar(sig, notchFreq, notchRQ);  //notch filter for 50/60 Hz
		chain= FFT(LocalBuf(bufferSize), sig);  //fft
		Array.fill(bins, {|i|
			var v= Demand.kr(chain>=0, 0, Unpack1FFT(chain, bufferSize, i));
			Out.kr(bus+i, v.sqrt.lag(lag).min(1));  //smooth and clip
		});
	}).load;
	bus= Bus.control(s, bins);
	CmdPeriod.doOnce({bus.free});
	s.sync;
	board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), false);
	Routine({
		synth.free;
		synth= Synth(\fft, [\bus, bus]);
		~synth= synth;
		s.sync;
		board.port= NetAddr.localAddr.port;
		0.1.wait;
		board.ip= ip;
		0.1.wait;
		board.setSampleRate(3);  //2000Hz
		0.1.wait;
		board.dataAction= {|num, data, aux, stop|
			synth.set(\data, data[index]/8388607);
		};
		board.start;
		task.stop;
		task= Routine.run({
			inf.do{
				fftArray= bus.getnSynchronous(bins);
				(1/61).wait;  //a tiny bit faster than framerate
			};
		});
		if(win.notNil, {win.close});
		win= Window("fft", Rect(100, 100, width, height), false);
		usr= UserView(win, Rect(0, 0, width, height));
		usr.animate= true;
		usr.frameRate= 60;
		//usr.clearOnRefresh= true;
		usr.background= Color.black;
		usr.drawFunc= {
			Pen.fillColor= Color.white;
			fftArray.size.do{|i|
				if(i%10==0, {
					Pen.stringAtPoint(i.asString, Point(i/bins*width, 10));
				});
			};
			fftArray.do{|y, x|
				Pen.addRect(Rect(x/bins*width, (1-y)*height, 1, height));
			};
			Pen.fill;
		};
		CmdPeriod.doOnce({win.close});
		win.front;
	}).play(AppClock);
	~openbci= board;
};
)


~synth.set(\loFreq, 3)
~synth.set(\hiFreq, 33)

~synth.set(\notchFreq, 50)
~synth.set(\notchFreq, 60)
~synth.set(\notchRq, 0.01)

~synth.set(\lag, 0.1)
~synth.set(\lag, 1)  //the default

~openbci.getSampleRate
~openbci.setSampleRate(2)
~openbci.setSampleRate(1)
~openbci.setSampleRate(0)
~openbci.latency= 4000
