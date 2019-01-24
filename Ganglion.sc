//--abstract class for openbci ganglion biosensing board communication

//related: GanglionSerial GanglionWifi Cyton

//http://docs.openbci.com/Hardware/08-Ganglion_Data_Format
//http://docs.openbci.com/OpenBCI%20Software/06-OpenBCI_Ganglion_SDK

Ganglion : OpenBCI {
	var <numChannels= 4;

	//--commands
	getSampleRate {  //get current sample rate
		this.prCommandArray("~~");
	}
	setSampleRate {|rate= 7|  //set sample rate
		this.prCommandArray("~"++rate.clip(0, 7));
	}

	startSquareWave {
		this.prCommand($[);
	}
	stopSquareWave {
		this.prCommand($]);
	}
	startImpedanceTest {
		this.prCommand($z);
	}
	stopImpedanceTest {
		this.prCommand($Z);
	}
	startAccelerometer {
		this.prCommand($n);
	}
	stopAccelerometer {
		this.prCommand($N);
	}
}
