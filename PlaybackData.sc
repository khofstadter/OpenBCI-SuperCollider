//--class for playing back OpenBCI data from a textfile

//TODO
//stream from disk instead?
//header first column, last column, other columns

PlaybackData : OpenBCI {
	classvar <numChannels= 8;
	classvar <defaultSampleRate= 250;
	var task, fileData, ctime= "";
	var <version, offset;
	uVScale {|gain= 24| ^4.5/gain/(2**23-1)*1000000}
	accScale {^0.002/(2**4)}

	*new {|path, dataAction, initAction, bufferSize= 512|
		^super.new(dataAction, nil, initAction, bufferSize).initPlaybackData(path);
	}
	initPlaybackData {|argPath|
		fileData= CSVFileReader.read(argPath.standardizePath);
		if(fileData[0][0].contains("%OpenBCI Raw EEG Data % %Sample Rate"), {
			version= 1;
			currentSampleRate= fileData[0][0].split($=)[1].asInteger;
			numChannels= fileData[1].size-1;
			offset= 1;
		}, {
			if(fileData[3][0].contains("%First Column"), {
				version= 3;
				currentSampleRate= fileData[2][0].split($=)[1].asInteger;
				numChannels= fileData[1][0].split($=)[1].asInteger;
				offset= 6;
			}, {
				if(fileData[3][0].contains("%Board"), {
					version= 5;
					currentSampleRate= fileData[2][0].split($=)[1].asInteger;
					numChannels= fileData[1][0].split($=)[1].asInteger;
					offset= 5;
				});
			});
		});
		if(version.notNil, {
			defaultSampleRate= currentSampleRate;
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
		(fileData.size-offset).do{|i|
			var line= fileData[i+offset];
			var nextLine;
			var num= line[0].asInteger;
			var time, nextTime;
			switch(version,
				5, {
					time= line[line.size-2].asFloat;
					ctime= line[line.size-1];
				},
				3, {
					time= line[line.size-1].asFloat;
					ctime= line[line.size-2];
				},
				1, {
					num= i-1%256;
				}
			);

			data= line.copyRange(1, numChannels).asFloat;
			if(version==1, {
				accel= #[0, 0, 0];
			}, {
				accel= line.copyRange(numChannels+1, numChannels+3).asFloat;
				if(accel[0]!=0 and:{accel[1]!=0 and:{accel[2]!=0}}, {
					accelAction.value(accel);
				});
			});
			this.updateBuffer(data);
			dataAction.value(num, data, accel);

			if(i+1+offset<fileData.size, {
				switch(version,
					5, {
						nextLine= fileData[i+1+offset];
						nextTime= nextLine[nextLine.size-2];
						(nextTime.asFloat-time*0.001).wait;
					},
					3, {
						nextLine= fileData[i+1+offset];
						nextTime= nextLine[nextLine.size-1];
						(nextTime.asFloat-time*0.001).wait;
					},
					1, {
						(1/currentSampleRate).wait;
					}
				);
			});
		};
		"%: done".format(this.class).postln;
	}
}
