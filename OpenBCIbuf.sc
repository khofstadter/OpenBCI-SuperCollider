//for collecting OpenBCI data and accelerometer values into buffers

OpenBCIbuf {
	var <board, <>size, dataFunc, accelFunc;
	var <dataBuffer, <accelBuffer;
	var <dataFull, <accelFull;  //maxed out flags
	*new {|board, maxSize= 1000|
		^super.new.initOpenBCIbuf(board, maxSize);
	}
	initOpenBCIbuf {|argBoard, argMaxSize|
		board= argBoard;
		size= argMaxSize;
		dataBuffer= List.new;
		accelBuffer= List.new;
		dataFull= false;
		accelFull= false;
		dataFunc= {|num, d, aux, stop|
			if(dataBuffer.size>=size, {
				dataBuffer.pop;
				if(dataFull.not, {
					"%: buffer data full. call readData more often or increase size".format(board.class.name).warn;
					dataFull= true;
				});
			});
			dataBuffer.insert(0, d);
		};
		accelFunc= {|a|
			if(accelBuffer.size>=size, {
				accelBuffer.pop;
				if(accelFull.not, {
					"%: buffer accel full. call readAccel more often or increase size".format(board.class.name).warn;
					accelFull= true;
				});
			});
			accelBuffer.insert(0, a);
		};
	}
	readData {
		var copy= dataBuffer;
		dataBuffer= List.new;
		^copy.reverse;
	}
	readAccel {
		var copy= accelBuffer;
		accelBuffer= List.new;
		^copy.reverse;
	}
	clear {
		dataBuffer= List.new;
		accelBuffer= List.new;
		dataFull= false;
		accelFull= false;
	}
	start {
		"%: buffering started".format(board.class.name).postln;
		board.dataAction= board.dataAction.removeFunc(dataFunc);  //safety
		board.accelAction= board.accelAction.removeFunc(accelFunc);  //safety
		board.dataAction= board.dataAction.addFunc(dataFunc);
		board.accelAction= board.accelAction.addFunc(accelFunc);
		CmdPeriod.add(this);
	}
	stop {
		board.dataAction= board.dataAction.removeFunc(dataFunc);
		board.accelAction= board.accelAction.removeFunc(accelFunc);
		"%: buffering stopped".format(board.class.name).postln;
		CmdPeriod.remove(this);
	}
	cmdPeriod {
		this.stop;
	}
}
