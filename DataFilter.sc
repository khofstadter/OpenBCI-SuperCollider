//--abstract class for filtering OpenBCI data

DataFilter {
	var <type;
	var <board, key;
	var data;
	var filt_b, filt_a;
	*keys {^this.constants.keys.asArray.sort}
	*new {|type|
		^super.new.init(type);
	}
	board_ {|b|
		var sr= b.currentSampleRate;
		var rates= this.class.constants[key].keys;
		board= b;
		if(rates.includes(sr).not, {
			"samplerate % not supported. only: %".format(sr, rates.asArray.sort).warn;
			sr= 250;
		});
		filt_b= this.class.constants[key][sr].b;  //TODO how to deal with freq and sr changes?
		filt_a= this.class.constants[key][sr].a;
		data= {DoubleArray.newClear(8)}.dup(b.numChannels);
	}
	filter {|rawData|
		var num= data[0].size;
		var nback= filt_b.size;
		board.numChannels.do{|c|
			var i= 0, j, out;
			var prev_y= DoubleArray.newClear(nback);
			var prev_x= DoubleArray.newClear(nback);
			data[c].pop;
			data[c].insert(0, rawData[c]);
			while({i<num}, {
				j= nback-1;
				while({j>0}, {
					prev_y[j]= prev_y[j-1];
					prev_x[j]= prev_x[j-1];
					j= j-1;
				});
				prev_x[0]= data[c][i];
				out= 0.0;
				while({j<nback}, {
					out= out+(filt_b[j]*prev_x[j]);
					if(j>0, {
						out= out-(filt_a[j]*prev_y[j]);
					});
					j= j+1;
				});
				prev_y[0]= out;
				data[c][i]= out;
				i= i+1;
			});
		};
		^data.collect{|d| d[data.size-1]};
	}
}