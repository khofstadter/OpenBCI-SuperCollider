//for performing fft on OpenBCI data

DataFFT {
	var <board, table, imag, <fftSize, <fftSize2, <bw;
	*new {|board, fftSize= 256|
		^super.new.initDataFFT(board, fftSize);
	}
	initDataFFT {|argBoard, argSize|
		board= argBoard;
		if(argSize.isPowerOfTwo.not, {
			argSize= argSize.nextPowerOfTwo;
			"%: not power-of-two. setting fftSize to %".format(this.class.name, argSize).warn;
		});
		fftSize= argSize;
		fftSize2= argSize.div(2);
		table= Signal.fftCosTable(fftSize);
		imag= Signal.newClear(fftSize);
		bw= 2/fftSize*(board.currentSampleRate*0.5);
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
	indexToFreq {|index|
		if(index==0, {
			^bw*0.25;
		}, {
			if(index==fftSize2, {
				^board.currentSampleRate*0.5-(bw*0.5)+(bw*0.25);
			}, {
				^index*bw;
			});
		});
	}
	freqToIndex {|freq|
		if(freq<(bw*0.5), {
			^0;
		}, {
			if(freq>(board.currentSampleRate*0.5-(bw*0.5)), {
				^fftSize2;
			}, {
				^(fftSize*(freq/board.currentSampleRate)).round.asInteger;
			});
		});
	}
}
