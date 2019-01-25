//for collecting OpenBCI data and perform fft

OpenBCIfft {
	var <board, <data, <fft, func, table, imag, size;
	*new {|board, sampleRate= 250|
		^super.new.initOpenBCIfft(board, sampleRate);
	}
	initOpenBCIfft {|argBoard, argSampleRate|
		board= argBoard;
		this.prInit(argSampleRate);
		func= {|num, d, aux, stop|
			board.numChannels.do{|i|
				data[i].pop;
				data[i].insert(0, d[i]/8388607);
				fft[i]= fft(data[i], imag, table).magnitude.copyRange(0, size.div(2));
			};
			fft;
		};
	}
	start {
		"%: fft started".format(board.class.name).postln;
		board.dataAction= board.dataAction.removeFunc(func);  //safety
		board.dataAction= board.dataAction.addFunc(func);
		CmdPeriod.add(this);
	}
	stop {
		board.dataAction= board.dataAction.removeFunc(func);
		"%: fft stopped".format(board.class.name).postln;
		CmdPeriod.remove(this);
	}
	cmdPeriod {
		this.stop;
	}

	//--private
	prInit {|sr|
		size= sr.nextPowerOfTwo;
		table= Signal.fftCosTable(size);
		imag= Signal.newClear(size);
		data= {Signal.newClear(size)}.dup(board.numChannels);
		fft= {Signal.newClear(size.div(2))}.dup(board.numChannels);
	}
}
