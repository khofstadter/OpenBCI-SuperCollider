//--abstract class for openbci ganglion biosensing board communication

//related: GanglionSerial GanglionWifi Cyton

//http://docs.openbci.com/Hardware/08-Ganglion_Data_Format
//http://docs.openbci.com/OpenBCI%20Software/06-OpenBCI_Ganglion_SDK

Ganglion : OpenBCI {
	var <numChannels= 4;
	var <defaultSampleRate= 200;

	//--commands
	getSampleRate {  //get current sample rate
		this.prCommandArray("~~");
	}
	setSampleRate {|rate= 7|  //set sample rate
		rate= rate.asInteger.clip(0, 7);
		if(this.isKindOf(GanglionSerial) and:{rate<7}, {
			rate= 7;
			"only 200Hz available for serial".warn;
		});
		this.prCommandArray("~"++rate);
		currentSampleRate= #[25600, 12800, 6400, 3200, 1600, 800, 400, 200][rate];
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
