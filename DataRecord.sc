//for logging OpenBCI data to a textfile

//TODO
//header first column, last column, other columns

DataRecord {
	var <board, <path, file;
	var dataFunc, separator;
	*new {|board, path|
		^super.new.initDataRecord(board, path);
	}
	initDataRecord {|argBoard, argPath|
		var timeStamp= Date.getDate.format("%Y-%m-%d_%H-%M-%S");
		board= argBoard;
		path= argPath ?? {ScIDE.currentPath.dirname+/+"savedData"};
		File.mkdir(path);
		path= path+/+"OpenBCI-RAW-"++timeStamp++"_sc.txt";
		file= File(path, "w");
		this.prWriteHeader;
		separator= ", ";
		dataFunc= {|num, data, accel|
			var time= Date.getDate;
			file.write(num.asString);
			file.write(separator);
			data.do{|d|
				file.write(d.round(0.01).asString);
				file.write(separator);
			};
			accel.do{|a|
				file.write(a.round(0.001).asString);
				file.write(separator);
			};
			file.write(time.format("%H:%M:"++(time.rawSeconds%60).round(0.001)));
			file.write(separator);
			file.write((time.rawSeconds*1000).round.asString.drop(-2));
			file.write(Char.nl);
		};
	}
	start {
		"%: recording started.\n %".format(this.class.name, path).postln;
		board.dataAction= board.dataAction.removeFunc(dataFunc);  //safety
		board.dataAction= board.dataAction.addFunc(dataFunc);
		CmdPeriod.add(this);
	}
	stop {
		board.dataAction= board.dataAction.removeFunc(dataFunc);
		file.close;
		"%: recording stopped.\n %".format(this.class.name, path).postln;
		CmdPeriod.remove(this);
	}
	cmdPeriod {
		this.stop;
	}

	//--private
	prWriteHeader {
		file.write("%OpenBCI Raw EEG Data\n");
		file.write("%Number of channels = "++board.numChannels++"\n");
		file.write("%Sample Rate = "++board.currentSampleRate++" Hz\n");
		file.write("%First Column = SampleIndex\n");
		file.write("%Last Column = Timestamp \n");
		file.write("%Other Columns = EEG data in microvolts followed by Accel Data (in G) interleaved with Aux Data\n");
	}
}
