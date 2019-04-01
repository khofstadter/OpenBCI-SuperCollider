//for distributing OpenBCI data and accelerometer values over time

DataSequencer {
	var <board, <data, <accel, <>size, dataFunc, accelFunc;
	var <dataBuffer, <accelBuffer;
	var dataTask, accelTask;
	var <>dataAction, <>accelAction;  //callback functions
	var <dataFull, <accelFull;  //maxed out flags
	var <>dataActive, <>accelActive;
	var <>factor= 0.99;
	*new {|board, maxSize= 1000, dataActive= true, accelActive= true|
		^super.new.initDataSequencer(board, maxSize, dataActive, accelActive);
	}
	initDataSequencer {|argBoard, argMaxSize, argDataActive, argAccelActive|
		board= argBoard;
		size= argMaxSize;
		dataActive= argDataActive;
		accelActive= argAccelActive;
		dataBuffer= List.new;
		accelBuffer= List.new;
		dataFull= false;
		accelFull= false;
		dataFunc= {|num, d, aux, stop|
			if(dataActive, {
				if(dataBuffer.size>=size, {
					dataBuffer.pop;
					if(dataFull.not, {
						"%: buffer data full. increase size".format(board.class.name).warn;
						dataFull= true;
					});
				});
				dataBuffer.insert(0, [num, d, aux, stop]);
			});
		};
		accelFunc= {|a|
			if(accelActive, {
				if(accelBuffer.size>=size, {
					accelBuffer.pop;
					if(accelFull.not, {
						"%: buffer accel full. increase size".format(board.class.name).warn;
						accelFull= true;
					});
				});
				accelBuffer.insert(0, a);
			});
		};
		dataTask= Routine({
			inf.do{
				var d= dataBuffer.pop;
				if(d.notNil, {
					data= d[1];
					dataAction.value(*d);  //num, data, aux, byte
				});
				(1/board.currentSampleRate*factor).wait;
			};
		});
		accelTask= Routine({
			inf.do{
				var a= accelBuffer.pop;
				if(a.notNil, {
					accel= a;
					accelAction.value(a);  //xyz
				});
				(0.04*factor).wait;  //accelerometer always 25Hz
			};
		});
	}
	clear {
		dataBuffer= List.new;
		accelBuffer= List.new;
		dataFull= false;
		accelFull= false;
	}
	start {
		"%: sequencing started".format(board.class.name).postln;
		board.dataAction= board.dataAction.removeFunc(dataFunc);  //safety
		board.accelAction= board.accelAction.removeFunc(accelFunc);  //safety
		board.dataAction= board.dataAction.addFunc(dataFunc);
		board.accelAction= board.accelAction.addFunc(accelFunc);
		dataTask.play(SystemClock);
		accelTask.play(SystemClock);
		CmdPeriod.add(this);
	}
	stop {
		dataTask.stop;
		dataTask.reset;
		accelTask.stop;
		accelTask.reset;
		board.dataAction= board.dataAction.removeFunc(dataFunc);
		board.accelAction= board.accelAction.removeFunc(accelFunc);
		"%: sequencing stopped".format(board.class.name).postln;
		CmdPeriod.remove(this);
	}
	cmdPeriod {
		this.stop;
	}
}
