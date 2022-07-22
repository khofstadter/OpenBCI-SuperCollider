//for performing fft on OpenBCI data

DataFFT {
	var <board, table, imag, <fftSize, <fftSize2, <bw;
	*new {|board, fftSize= 256, windowType|
		^super.new.initDataFFT(board, fftSize, windowType);
	}
	initDataFFT {|argBoard, argSize, argWindowType|
		board= argBoard;
		if(argSize.isPowerOfTwo.not, {
			argSize= argSize.nextPowerOfTwo;
			"%: not power-of-two. setting fftSize to %".format(this.class.name, argSize).warn;
		});
		fftSize= argSize;
		fftSize2= argSize.div(2);
		table= switch(argWindowType,
			\hamming, {
				Signal.hammingWindow(fftSize2+2).copyToEnd(fftSize2.div(2)+1);
			},
			\hanning, {
				Signal.hanningWindow(fftSize2+2).copyToEnd(fftSize2.div(2)+1);
			},
			\rect, {
				Signal.rectWindow(fftSize2+2).copyToEnd(fftSize2.div(2)+1);
			},
			\welch, {
				Signal.welchWindow(fftSize2+2).copyToEnd(fftSize2.div(2)+1);
			},
			{
				Signal.fftCosTable(fftSize);
			}
		);
		imag= Signal.newClear(fftSize);
		bw= 2/fftSize*(board.currentSampleRate*0.5);
	}
	fft {|data|
		var complex;
		if(data.size<fftSize, {
			"%: data size must be >= fftSize. zeropadded % values".format(this.class.name, fftSize-data.size).warn;
			data= 0.dup(fftSize-data.size)++data;
		});
		data= data.copyRange(data.size-fftSize, data.size-1);
		data= data-(data.sum/data.size);  //remove mean
		complex= fft(data.as(Signal), imag, table);
		^complex.real.copyRange(0, fftSize2).hypot(complex.imag.copyRange(0, fftSize2))/fftSize2;
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
