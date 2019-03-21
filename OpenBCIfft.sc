//for performing fft on OpenBCI buffer

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
	fft {|buffer, channel= 0|
		var length, signal;
		if(channel>=board.numChannels or:{channel<0}, {
			"%: channel out of range. clipped to 0-%".format(this.class.name, board.numChannels-1).warn;
			channel= channel.clip(0, board.numChannels-1);
		});
		length= buffer[channel].size;
		signal= buffer[channel].copyRange(length-fftSize, length-1).as(Signal);
		^fft(signal, imag, table).magnitude.copyRange(0, fftSize2)/fftSize2;
	}
}
