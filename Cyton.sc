//--abstract class for openbci cyton biosensing board communication

//related: CytonSerial CytonWifi Ganglion

//https://docs.openbci.com/Cyton/CytonDataFormat/
//https://docs.openbci.com/Cyton/CytonSDK/

Cyton : OpenBCIboard {
	classvar <numChannels= 8;
	classvar <defaultSampleRate= 250;
	uVScale {|gain= 24| ^4.5/gain/(2**23-1)*1000000}
	accScale {^0.002/(2**4)}

	//--commands
	testGnd {  //Connect to internal GND (VDD - VSS)
		this.prCommand($0);
	}
	test1AmpSlow {  //Connect to test signal 1xAmplitude, slow pulse
		this.prCommand($-);
	}
	test1AmpFast {  //Connect to test signal 1xAmplitude, fast pulse
		this.prCommand($=);
	}
	testDC {  //Connect to DC signal
		this.prCommand($p);
	}
	test2AmpSlow {  //Connect to test signal 2xAmplitude, slow pulse
		this.prCommand($[);
	}
	test2AmpFast {  //Connect to test signal 2xAmplitude, fast pulse
		this.prCommand($]);
	}

	settings {|channel= 1, powerDown= 0, gain= 6, type= 0, bias= 1, srb2= 1, srb1= 0|
		if(channel>=1 and:{channel<=numChannels}, {
			this.prCommandArray(
				"x%%%%%%%X".format(
					channel,
					powerDown.clip(0, 1),
					gain.clip(0, 6),
					type.clip(0, 7),
					bias.clip(0, 1),
					srb2.clip(0, 1),
					srb1.clip(0, 1)
				)
			);
		}, {
			"channel % out of range".format(channel).warn;
		});
	}
	setDefaultChannelSettings {  //set all channels to default
		this.prCommand($d);
	}
	getDefaultChannelSettings {  //get a report
		this.prCommand($D);
	}
	impedance {|channel= 1, pchan= 0, nchan= 1|
		if(channel>=1 and:{channel<=numChannels}, {
			this.prCommandArray(
				"z%%%Z".format(
					channel,
					pchan.clip(0, 1),
					nchan.clip(0, 1)
				)
			);
		}, {
			"channel % out of range".format(channel).warn;
		});
	}

	timeStampingON {
		this.prCommand($<);
	}
	timeStampingOFF {
		this.prCommand($>);
	}
	getRadioChannel {  //Get Radio Channel Number
		this.prCommandArray(Int8Array[0xF0, 0x00]);
	}
	setRadioChannel {|channel= 7|  //Set Radio System Channel Number
		this.prCommandArray(Int8Array[0xF0, 0x01, channel.clip(1, 25)]);
	}
	setRadioHostChannel {|channel= 7, really= false|  //Set Host Radio Channel Override
		if(really, {  //extra safety
			this.prCommandArray(Int8Array[0xF0, 0x02, channel.clip(1, 25)]);
		}, {
			"changing might break the wireless connection. really=true to override".warn;
		});
	}
	getRadioPollTime {  //Radio Get Poll Time
		this.prCommandArray(Int8Array[0xF0, 0x03]);
	}
	setRadioPollTime {|time= 80|  //Radio Set Poll Time
		this.prCommandArray(Int8Array[0xF0, 0x04, time.clip(0, 255)]);
	}
	setRadioHostBaudRate {|rate= 0, really= false|  //Radio Set HOST to Driver Baud Rate
		if(really, {  //extra safety
			switch(rate,
				0, {this.prCommandArray(Int8Array[0xF0, 0x05])},  //Default - 115200
				1, {this.prCommandArray(Int8Array[0xF0, 0x06])},  //High-Speed - 230400
				2, {this.prCommandArray(Int8Array[0xF0, 0x0A])},  //Hyper-Speed - 921600
				{"rate % not recognised".format(rate).warn}
			);
		}, {
			"changing will break the serial connection. really=true to override".warn;
		});
	}
	getRadioSystemStatus {  //Radio System Status
		this.prCommandArray(Int8Array[0xF0, 0x07]);
	}
	getSampleRate {  //get current sample rate
		this.prCommandArray("~~");
	}
	setSampleRate {|rate= 6|  //set sample rate
		rate= rate.asInteger.clip(0, 6);
		if(this.isKindOf(CytonSerial) and:{rate<6}, {
			rate= 6;
			"only 250Hz available for serial".warn;
		});
		this.prCommandArray("~"++rate);
		currentSampleRate= #[16000, 8000, 4000, 2000, 1000, 500, 250][rate];
	}
	getBoardMode {  //get current board mode
		this.prCommandArray("//");
	}
	setBoardMode {|mode= 0|  //set board mode
		this.prCommandArray("/"++mode.clip(0, 4));
	}

	getVersion {  //get firmware version
		this.prCommand($V);
	}
}

CytonDaisy : Cyton {
	classvar <numChannels= 16;

	//--commands
	settings {|channel= 1, powerDown= 0, gain= 6, type= 0, bias= 1, srb2= 1, srb1= 0|
		if(channel>=1 and:{channel<=numChannels}, {
			this.prCommandArray(
				"x%%%%%%%X".format(
					switch(channel,
						9, {$Q},
						10, {$W},
						11, {$E},
						12, {$R},
						13, {$T},
						14, {$Y},
						15, {$U},
						16, {$I},
						{channel}
					),
					powerDown.clip(0, 1),
					gain.clip(0, 6),
					type.clip(0, 7),
					bias.clip(0, 1),
					srb2.clip(0, 1),
					srb1.clip(0, 1)
				)
			);
		}, {
			"channel % out of range".format(channel).warn;
		});
	}
	maximumChannelNumber {|channels= 16|
		switch(channels,
			8, {this.prCommand($c)},
			16, {this.prCommand($C)},
			{"channels can only be 8 or 16".warn}
		);
	}
}
