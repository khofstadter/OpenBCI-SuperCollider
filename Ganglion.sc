//--supercollider openbci ganglion biosensing board (4-channels) communication

//http://docs.openbci.com/Hardware/08-Ganglion_Data_Format
//http://docs.openbci.com/OpenBCI%20Software/06-OpenBCI_Ganglion_SDK

Ganglion : OpenBCI {

	off {|channel= 1|  //Turn Channels OFF
		channel.asArray.do{|c|
			switch(c,
				1, {port.put($1)},
				2, {port.put($2)},
				3, {port.put($3)},
				4, {port.put($4)},
				{"channel % not in the range 1-4".format(c).warn}
			);
		};
	}
	on {|channel= 1|  //Turn Channels ON
		channel.asArray.do{|c|
			switch(c,
				1, {port.put($!)},
				2, {port.put($@)},
				3, {port.put($#)},
				4, {port.put($$)},
				{"channel % not in the range 1-4".format(c).warn}
			);
		};
	}

	getSampleRate {  //get current sample rate
		port.putAll("~~");
	}
	setSampleRate {|rate= 7|  //set sample rate
		port.putAll("~"++rate.clip(0, 7));
		if(rate<7, {
			"The Ganglion cannot and will not stream data over 200SPS".warn;
		});
	}
}
