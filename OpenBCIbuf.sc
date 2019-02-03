//for collecting OpenBCI data and accelerometer values into buffers

OpenBCIbuf {
	var <board, <data, <accel, funcData, funcAccel, <>size;
	var <dataFull, <accelFull;  //maxed out flags
	*new {|board, maxSize= 1000|
		^super.new.initOpenBCIbuf(board, maxSize);
	}
	initOpenBCIbuf {|argBoard, argMaxSize|
		board= argBoard;
		size= argMaxSize;
		data= List.new;
		accel= List.new;
		dataFull= false;
		accelFull= false;
		funcData= {|num, d, aux, stop|
			if(data.size>=size, {
				data.pop;
				if(dataFull.not, {
					"%: buffer data full. call readData more often or increase size".format(board.class.name).warn;
					dataFull= true;
				});
			});
			data.insert(0, d);
		};
		funcAccel= {|a|
			if(accel.size>=size, {
				accel.pop;
				if(accelFull.not, {
					"%: buffer accel full. call readAccel more often or increase size".format(board.class.name).warn;
					accelFull= true;
				});
			});
			accel.insert(0, a);
		};
	}
	readData {
		var copy= data;
		data= List.new;
		^copy.reverse;
	}
	readAccel {
		var copy= accel;
		accel= List.new;
		^copy.reverse;
	}
	clear {
		data= List.new;
		accel= List.new;
		dataFull= false;
		accelFull= false;
	}
	start {
		"%: buffering started".format(board.class.name).postln;
		board.dataAction= board.dataAction.removeFunc(funcData);  //safety
		board.accelAction= board.accelAction.removeFunc(funcAccel);  //safety
		board.dataAction= board.dataAction.addFunc(funcData);
		board.accelAction= board.accelAction.addFunc(funcAccel);
		CmdPeriod.add(this);
	}
	stop {
		board.dataAction= board.dataAction.removeFunc(funcData);
		board.dataAction= board.accelAction.removeFunc(funcAccel);
		"%: buffering stopped".format(board.class.name).postln;
		CmdPeriod.remove(this);
	}
	cmdPeriod {
		this.stop;
	}
}
