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
}
