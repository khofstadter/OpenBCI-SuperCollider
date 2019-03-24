//for smoothing OpenBCI data

OpenBCIlag {
	var <>factor;
	var prevData;
	*new {|factor= 0.9|
		^super.new.initOpenBCIlag(factor);
	}
	initOpenBCIlag {|argFactor|
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
