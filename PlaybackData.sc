//--class for playing back OpenBCI data from a textfile

//TODO
//stream from disk instead?
//header first column, last column, other columns

PlaybackData : OpenBCI {
	classvar <numChannels= 8;
	classvar <defaultSampleRate= 250;
	var task, fileData, ctime= "";
	uVScale {|gain= 24| ^4.5/gain/(2**23-1)*1000000}
	accScale {^0.002/(2**4)}

	*new {|path, dataAction, initAction, bufferSize= 512|
		^super.new(dataAction, nil, initAction, bufferSize).initPlaybackData(path);
	}
	initPlaybackData {|argPath|
		fileData= CSVFileReader.read(argPath.standardizePath);
		if(fileData[0][0].contains("%OpenBCI Raw EEG Data"), {
			currentSampleRate= fileData[2][0].split($=)[1].asFloat;
			defaultSampleRate= currentSampleRate;
			numChannels= fileData[1][0].split($=)[1].asInteger;
			buffer= {List.fill(bufferSize, {0})}.dup(numChannels);  //need to recreate buffer because numChannels is nil

			initAction.value(this, "init playback data");
			CmdPeriod.add(this);
		}, {
			"%: could not parse file header".format(this.class).error;
		});
	}
	start {
		task.stop;
		task= Routine({this.prTask}).play(SystemClock);
	}
	stop {
		"%: stopping file playback".format(this.class.name).postln;
		task.stop;
		CmdPeriod.remove(this);
		ctime= "";
	}
	softReset {
		currentSampleRate= this.class.defaultSampleRate;
	}
	close {
		this.stop;
	}
	cmdPeriod {
		this.stop;
	}
	currentTime {
		^ctime.stripWhiteSpace;
	}

	//--private
	prTask {
		(fileData.size-6).do{|i|
			var line= fileData[i+6];
			var num= line[0].asInteger;
			var time= line[line.size-1].asFloat;
			ctime= line[line.size-2];

			data= line.copyRange(1, numChannels).asFloat;
			accel= line.copyRange(numChannels+1, numChannels+3).asFloat;
			if(accel[0]!=0 and:{accel[1]!=0 and:{accel[2]!=0}}, {
				accelAction.value(accel);
			});
			this.updateBuffer(data);
			dataAction.value(num, data, accel);

			if(i+7<fileData.size, {
				(fileData[i+7].last.asFloat-time*0.001).wait;
			});
		};
		"%: done".format(this.class).postln;
	}
}
