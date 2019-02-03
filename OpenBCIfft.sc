//for collecting OpenBCI data and perform fft

OpenBCIfft {
	var <board, data, func, table, imag, <fftSize, fftSize2;
	*new {|board, fftSize= 256|
		^super.new.initOpenBCIfft(board, fftSize);
	}
	initOpenBCIfft {|argBoard, argSize|
		board= argBoard;
		if(argSize.isPowerOfTwo.not, {
			argSize= argSize.nextPowerOfTwo;
			"%: not power-of-two. setting fftSize to %".format(this.class.name, argSize).warn;
		});
		fftSize= argSize;
		fftSize2= argSize.div(2);
		table= Signal.fftCosTable(fftSize);
		imag= Signal.newClear(fftSize);
		data= {Signal.newClear(fftSize)}.dup(board.numChannels);
		func= {|num, d, aux, stop|
			board.numChannels.do{|i|
				data[i].pop;
				data[i].insert(0, d[i].linlin(-8388608, 8388607, -1, 1));
			};
		};
	}
	fft {|channel= 0|
		if(channel>=board.numChannels or:{channel<0}, {
			"%: channel out of range. clipped to 0-%".format(this.class.name, board.numChannels-1).warn;
			channel= channel.clip(0, board.numChannels-1);
		});
		^fft(data[channel], imag, table).magnitude.copyRange(0, fftSize2)/fftSize2;
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
}
