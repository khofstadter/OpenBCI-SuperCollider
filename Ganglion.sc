//--supercollider openbci ganglion biosensing board (4-channels) communication

//http://docs.openbci.com/Hardware/08-Ganglion_Data_Format
//http://docs.openbci.com/OpenBCI%20Software/06-OpenBCI_Ganglion_SDK

Ganglion : OpenBCI {
	classvar <numChannels= 4;

	getSampleRate {  //get current sample rate
		port.putAll("~~");
	}
	setSampleRate {|rate= 7|  //set sample rate
		port.putAll("~"++rate.clip(0, 7));
		if(rate<7, {
			"The Ganglion cannot and will not stream data over 200SPS".warn;
		});
	}

	startSquareWave {
		port.put($[);
	}
	stopSquareWave {
		port.put($]);
	}
	startImpedanceTest {
		port.put($z);
	}
	stopImpedanceTest {
		port.put($Z);
	}
	startAccelerometer {
		port.put($n);
	}
	stopAccelerometer {
		port.put($N);
	}

	//--private
	prInit {}
	prTask {  //TODO
		var last3= [0, 0, 0];
		var buffer= List(32);
		var state= 0;
	}
}
