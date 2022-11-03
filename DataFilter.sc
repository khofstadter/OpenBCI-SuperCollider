//--abstract class for filtering OpenBCI data

DataFilter {
	var <type, <sampleRate;
	var <filt_b, <filt_a;
	var nconst, clear, prev_x, prev_y;
	var dataN, prev_xN, prev_yN, kN;
	*keys {^this.constants.keys.asArray.sort}
	*new {|type, sampleRate, bufferSize|
		^super.new.initDataFilter(type, sampleRate, bufferSize);
	}
	initDataFilter {|argType, argSampleRate, argBufferSize|
		type= argType;
		if(this.class.constants.keys.includes(type).not, {
			"type % not supported. only: %".format(type, this.class.constants.keys.asArray).warn;
			type= this.class.constants.keys.asArray[0];
		});
		this.sampleRate_(argSampleRate?250);  //set a default
		this.bufferSize_(argBufferSize?1250);
	}
	bufferSize_ {|val|
		dataN= FloatArray.newClear(val);
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
		prev_xN= clear.copy;
		prev_yN= clear.copy;
		kN= 0;
	}
	filter {|data|
		var i= 0, j, k= 0, l, out, size= data.size;
		data= data.copy;
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
	filterN {|newData|
		var i= 0, j, l, out, size= dataN.size;
		var nd= newData.asCollection;
		var index= size-nd.size;
		dataN= dataN.drop(nd.size).addAll(nd);
		while({i<nd.size}, {
			kN= (kN-1).mod(nconst);
			prev_xN[kN]= dataN[index+i];
			out= filt_b[0]*prev_xN[kN];
			j= 1;
			while({j<nconst}, {
				l= (j+kN).mod(nconst);
				out= out+(filt_b[j]*prev_xN[l]);
				out= out-(filt_a[j]*prev_yN[l]);
				j= j+1;
			});
			prev_yN[kN]= out;
			dataN[index+i]= out;
			i= i+1;
		});
		^dataN;
	}
}
