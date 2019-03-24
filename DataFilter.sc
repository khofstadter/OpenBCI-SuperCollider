//--abstract class for filtering OpenBCI data

DataFilter {
	var <type, <sr;
	var <filt_b, <filt_a;
	var nconst, clear;
	*keys {^this.constants.keys.asArray.sort}
	*new {|type|
		^super.new.initDataFilter(type);
	}
	initDataFilter {|argType|
		type= argType;
		if(this.class.constants.keys.includes(type).not, {
			"type % not supported. only: %".format(type, this.class.constants.keys.asArray).warn;
			type= this.class.constants.keys.asArray[0];
		});
		this.sr_(250);  //set a default
	}
	sr_ {|sampleRate= 250|
		var rates= this.class.constants[type].keys;
		if(rates.includes(sampleRate).not, {
			"samplerate % not supported. only: %".format(sampleRate, rates.asArray.sort).warn;
			sr= 250;
		}, {
			sr= sampleRate;
		});
		filt_b= this.class.constants[type][sr].b;  //TODO how to deal with freq and sr changes?
		filt_a= this.class.constants[type][sr].a;
		nconst= filt_b.size;
		clear= 0.dup(nconst);
	}
	filter {|data|
		var prev_y= clear.copy;
		var prev_x= clear.copy;
		var j, out;
		^Array.fill(data.size, {|i|
			prev_y= prev_y.rotate(1);
			prev_x= prev_x.rotate(1);
			prev_x[0]= data[i];
			out= filt_b[0]*prev_x[0];
			j= 1;
			while({j<nconst}, {
				out= out+(filt_b[j]*prev_x[j]);
				out= out-(filt_a[j]*prev_y[j]);
				j= j+1;
			});
			prev_y[0]= out;
			out;
		});
	}
}
