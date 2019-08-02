//checking impedance on a channel

~openbci= CytonSerial("/dev/tty.usbserial-DM00DRM0");
//~openbci= SyntheticData();
~channel= 1;  //channel to check

(
~notchFilter= DataFilterNotch('50');  //set to 60 for 60Hz notch filter
~bandpassFilter= DataFilterBandpass('1-50');
//~bandpassFilter= DataFilterBandpass('5-50');
//~bandpassFilter= DataFilterBandpass('15-50');
//~bandpassFilter= DataFilterBandpass('7-13');

~std= {
|arr|

	var val= 0;
	var average= arr.mean;
	arr.do{
|a|

		val= val+pow(a-average, 2);
	};
	sqrt(val= val/arr.size);
};
~impedance= {
|uV|

	var impedance= sqrt(2)*uV*1e-6/6e-9;
	impedance= impedance-2200;
};
~openbci.dataAction= {
|num|

	var ohms;
	var bufferedData;
	if(num%10==0, {
		bufferedData= ~openbci.buffer[~channel-1];
		bufferedData= bufferedData.keep(0-~openbci.currentSampleRate);  //1sec
		bufferedData= ~notchFilter.filter(bufferedData);
		bufferedData= ~bandpassFilter.filter(bufferedData);
		ohms= ~impedance.value(~std.value(bufferedData));
		"imp ch%: %KOhms".format(~channel, ohms/1000).postln;
	});
};
~openbci.off((1..~openbci.numChannels));  //turn off all
~openbci.on(~channel);  //only active one channel at a time
)

~openbci.start;  //start streaming

~openbci.impedance(~channel, 0, 1);  //activate test signal on channel