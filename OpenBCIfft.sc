//for collecting OpenBCI data and perform fft

OpenBCIfft {
	var <board, <data, <fft, func, table, imag, size, numChannels;
	*new {|board, sampleRate= 250|
		^super.new.initOpenBCIfft(board, sampleRate);
	}
	initOpenBCIfft {|argBoard, argSampleRate|
		board= argBoard;
		numChannels= board.class.numChannels;
		this.prInit(argSampleRate);
		CmdPeriod.doOnce({this.stop});
	}
	start {
		"%: fft started".format(board.class.name).postln;
		func= {|num, d, aux, stop|
			numChannels.do{|i|
				data[i].pop;
				data[i].insert(0, d[i]/8388607);
				fft[i]= fft(data[i], imag, table).magnitude.copyRange(0, size.div(2));
			};
			fft;
		};
		board.dataAction= board.dataAction.addFunc(func);
	}
	stop {
		board.dataAction= board.dataAction.removeFunc(func);
		"%: fft stopped".format(board.class.name).postln;
	}

	//--private
	prInit {|sr|
		size= sr.nextPowerOfTwo;
		table= Signal.fftCosTable(size);
		imag= Signal.newClear(size);
		data= {Signal.newClear(size)}.dup(numChannels);
		fft= {Signal.newClear(size.div(2))}.dup(numChannels);
	}
}
