//for smoothing OpenBCI data

DataSmoothing {
	var <>factor;
	var prevData;
	*new {|factor= 0.9|
		^super.new.initDataSmoothing(factor);
	}
	initDataSmoothing {|argFactor|
		factor= argFactor;
	}
	filter {|data|
		if(prevData.notNil, {
			data= factor*prevData+((1-factor)*data);
		});
		prevData= data;
		^data;
	}
	filterLog {|data|
		if(prevData.notNil, {
			data= (1-factor)*data.pow(2).log;
			data= factor*prevData.pow(2).log+data;
			data= data.exp.sqrt;
		});
		prevData= data;
		^data;
	}
}
