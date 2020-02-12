//--abstract class for openbci ganglion biosensing board communication

//related: GanglionSerial GanglionWifi Cyton

//https://docs.openbci.com/docs/03Ganglion/GanglionDataFormat
//https://docs.openbci.com/docs/03Ganglion/GanglionSDK

Ganglion : OpenBCIboard {
	classvar <numChannels= 4;
	classvar <defaultSampleRate= 200;
	uVScale {^(1.2*1000000)/(8388607*1.5*51)}
	accScale {^0.032}

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
