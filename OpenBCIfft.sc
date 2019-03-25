//for performing fft on OpenBCI data

OpenBCIfft {
	var <board, table, imag, <fftSize, fftSize2;
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
	}
	fft {|data|
		var signal;
		if(data.size<fftSize, {
			"%: data size must be >= fftSize. zeropadded % values".format(this.class.name, fftSize-data.size).warn;
			data= 0.dup(fftSize-data.size)++data;
		});
		signal= data.copyRange(data.size-fftSize, data.size-1).as(Signal);
		^fft(signal, imag, table).magnitude.copyRange(0, fftSize2)/fftSize2;
	}
}
