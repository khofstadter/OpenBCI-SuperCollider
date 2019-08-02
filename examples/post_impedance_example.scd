//checking impedance on a channel
//TODO ganglion board

~openbci= CytonSerial("/dev/tty.usbserial-DM00DRM0");
~channel= 1;  //channel to check

(
~notchFilter= DataFilterNotch('50');  //set to 60 for 60Hz notch filter
~bandpassFilter= DataFilterBandpass('1-50');  //options '5-50', '15-50', '7-13'

~std= {|arr|
	var val= 0;
	var average= arr.mean;
	arr.do{|a|
		val= val+pow(a-average, 2);
	};
	sqrt(val= val/arr.size);
};
~impedance= {|uV|
	var impedance= sqrt(2)*uV*1e-6/6e-9;
	impedance= impedance-2200;  //NOTE: cyton board only 2K2 resistor
};
~openbci.dataAction= {|num|
	var ohms;
	var bufferedData;
	if(num%10==0, {  //only calculate and post every 10th reading
		bufferedData= ~openbci.buffer[~channel-1];
		bufferedData= ~notchFilter.filter(bufferedData);
		bufferedData= ~bandpassFilter.filter(bufferedData);
		bufferedData= bufferedData.keep(0-~openbci.currentSampleRate);  //1sec
		ohms= ~impedance.value(~std.value(bufferedData));
		"imp ch%: %KOhms".format(~channel, ohms/1000).postln;
	});
};
~openbci.off((1..~openbci.numChannels));  //turn off all
~openbci.on(~channel);  //only active one channel at a time
)

~openbci.start;  //start streaming

~openbci.impedance(~channel, 0, 1);  //activate test signal on channel
