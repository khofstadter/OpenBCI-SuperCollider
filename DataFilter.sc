//--abstract class for filtering OpenBCI data

DataFilter {
	var <type, <sampleRate;
	var <filt_b, <filt_a;
	var nconst, clear, prev_x, prev_y;
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
		this.sampleRate_(250);  //set a default
	}
	sampleRate_ {|rate= 250|
		var rates= this.class.constants[type].keys;
		if(rates.includes(rate).not, {
			"samplerate % not supported. only: %".format(rate, rates.asArray.sort).warn;
			sampleRate= 250;
		}, {
			sampleRate= rate;
		});
		filt_b= this.class.constants[type][sampleRate].b;  //TODO how to deal with freq and sr changes?
		filt_a= this.class.constants[type][sampleRate].a;
		nconst= filt_b.size;
		clear= DoubleArray.newClear(nconst);
	}
	filter {|data|
		var i= 0, j, k= 0, l, out, size= data.size;
		prev_x= clear.copy;
		prev_y= clear.copy;
		while({i<size}, {
			k= (k-1).mod(nconst);
			prev_x[k]= data[i];
			out= filt_b[0]*prev_x[k];
			j= 1;
			while({j<nconst}, {
				l= (j+k).mod(nconst);
				out= out+(filt_b[j]*prev_x[l]);
				out= out-(filt_a[j]*prev_y[l]);
				j= j+1;
			});
			prev_y[k]= out;
			data[i]= out;
			i= i+1;
		});
		^data;
	}
}
