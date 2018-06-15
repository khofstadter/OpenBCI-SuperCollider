//--supercollider openbci cyton biosensing board (8-channels) communication

//http://docs.openbci.com/Hardware/03-Cyton_Data_Format
//http://docs.openbci.com/OpenBCI%20Software/04-OpenBCI_Cyton_SDK

//TODO: implement and test the different aux commands
//TODO: low pass filter
//TODO: notch filter (60/50 hz)
//TODO: test wifi shield commands
//TODO: test Daisy commands

Cyton : OpenBCI {
	classvar <numChannels= 8;

	//--commands
	testGnd {  //Connect to internal GND (VDD - VSS)
		port.put($0);
	}
	test1AmpSlow {  //Connect to test signal 1xAmplitude, slow pulse
		port.put($-);
	}
	test1AmpFast {  //Connect to test signal 1xAmplitude, fast pulse
		port.put($=);
	}
	testDC {  //Connect to DC signal
		port.put($p);
	}
	test2AmpSlow {  //Connect to test signal 2xAmplitude, slow pulse
		port.put($[);
	}
	test2AmpFast {  //Connect to test signal 2xAmplitude, fast pulse
		port.put($]);
	}

	settings {|channel= 1, powerDown= 0, gain= 6, type= 0, bias= 1, srb2= 1, srb1= 0|
		if(channel>=1 and:{channel<=8}, {
			port.put($x);
			port.put(channel.asDigit);
			port.put(powerDown.clip(0, 1).asDigit);
			port.put(gain.clip(0, 6).asDigit);
			port.put(type.clip(0, 7).asDigit);
			port.put(bias.clip(0, 1).asDigit);
			port.put(srb2.clip(0, 1).asDigit);
			port.put(srb1.clip(0, 1).asDigit);
			port.put($X);
		}, {
			"channel % out of range".format(channel).warn;
		});
	}
	setDefaultChannelSettings {  //set all channels to default
		port.put($d);
	}
	getDefaultChannelSettings {  //get a report
		port.put($D);
	}
	impedance {|channel= 1, pchan= 0, nchan= 0|
		if(channel>=1 and:{channel<=8}, {
			port.put($z);
			port.put(channel.asDigit);
			port.put(pchan.clip(0, 1).asDigit);
			port.put(nchan.clip(0, 1).asDigit);
			port.put($Z);
		}, {
			"channel % out of range".format(channel).warn;
		});
	}

	timeStampingON {
		port.put($<);
	}
	timeStampingOFF {
		port.put($>);
	}
	getRadioChannel {  //Get Radio Channel Number
		port.putAll(Int8Array[0xF0, 0x00]);
	}
	setRadioChannel {|channel= 7|  //Set Radio System Channel Number
		port.putAll(Int8Array[0xF0, 0x01, channel.clip(1, 25)]);
	}
	setRadioHostChannel {|channel= 7, really= false|  //Set Host Radio Channel Override
		if(really, {  //extra safety
			port.putAll(Int8Array[0xF0, 0x02, channel.clip(1, 25)]);
		}, {
			"changing might break the wireless connection. really=true to override".warn;
		});
	}
	getRadioPollTime {  //Radio Get Poll Time
		port.putAll(Int8Array[0xF0, 0x03]);
	}
	setRadioPollTime {|time= 80|  //Radio Set Poll Time
		port.putAll(Int8Array[0xF0, 0x04, time.clip(0, 255)]);
	}
	setRadioHostBaudRate {|rate= 0, really= false|  //Radio Set HOST to Driver Baud Rate
		if(really, {  //extra safety
			switch(rate,
				0, {port.putAll(Int8Array[0xF0, 0x05])},  //Default - 115200
				1, {port.putAll(Int8Array[0xF0, 0x06])},  //High-Speed - 230400
				2, {port.putAll(Int8Array[0xF0, 0x0A])},  //Hyper-Speed - 921600
				{"rate % not recognised".format(rate).warn}
			);
		}, {
			"changing will break the serial connection. really=true to override".warn;
		});
	}
	getRadioSystemStatus {  //Radio System Status
		port.putAll(Int8Array[0xF0, 0x07]);
	}
	getSampleRate {  //get current sample rate
		port.putAll("~~");
	}
	setSampleRate {|rate= 6|  //set sample rate
		port.putAll("~"++rate.clip(0, 6));
		if(rate<6, {
			"The Cyton with USB Dongle cannot and will not stream data over 250SPS".warn;
		});
	}
	getBoardMode {  //get current board mode
		port.putAll("//");
	}
	setBoardMode {|mode= 0|  //set board mode
		port.putAll("/"++mode.clip(0, 4));
	}

	getVersion {  //get firmware version
		port.put($V);
	}

	//--private
	prTask {
		var last3= [0, 0, 0];
		var buffer= List(32);
		var state= 0;
		var reply, num, aux= (26..31);
		0.1.wait;
		inf.do{|i|
			var byte= port.read;
			//byte.postln;  //debug
			buffer.add(byte);
			switch(state,
				0, {
					if(byte==0xA0, {  //header
						if(buffer.size>1, {
							buffer= List(32);
							buffer.add(byte);
						});
						state= 1;
					}, {
						last3[i%3]= byte;
						if(last3==#[36, 36, 36], {  //eot $$$
							if(buffer[0]==65, {  //TODO remove this
								buffer= buffer.drop(32);
								//"temp fix applied".postln;  //debug
							});
							reply= "";
							(buffer.size-3).do{|i| reply= reply++buffer[i].asAscii};
							if(reply.contains("OpenBCI V3 8-16 channel"), {
								initAction.value(reply);
							});
							replyAction.value(reply);
							buffer= List(32);
						});
					});
				},
				1, {
					if(buffer.size>=32, {
						state= 2;
					});
				},
				2, {
					if(byte>=0xC0 and:{byte<=0xCF}, {  //check valid footer
						num= buffer[1];  //sample number
						data= Array.fill(numChannels, {|i|  //eight channels of 24bit data
							var msb= buffer[i*3+2];
							var pre= 0;
							if(msb&128>0, {
								pre= -0x01000000;
							});
							pre+(msb<<16)+(buffer[i*3+3]<<8)+buffer[i*3+4];
						});
						switch(byte,  //footer / stop byte
							0xC0, {  //accelerometer
								if(aux.any{|i| buffer[i]!=0}, {
									accel= Array.fill(3, {|i|  //three dimensions of 16bit data
										var msb= buffer[i*2+26];
										var pre= 0;
										if(msb&128>0, {
											pre= -0x010000;
										});
										pre+(msb<<8)+buffer[i*2+27];
									});
									accelAction.value(accel);
								});
							};
						);
						dataAction.value(num, data, buffer[aux], byte);
					}, {
						buffer.postln;
						("% read error").format(this.class.name).postln;
					});
					buffer= List(32);
					state= 0;
				}
			);
		};
	}
}

CytonDaisy : Cyton {
	classvar <numChannels= 16;
	settings {|channel= 1, powerDown= 0, gain= 6, type= 0, bias= 1, srb2= 1, srb1= 0|
		if(channel>=1 and:{channel<=16}, {
			port.put($x);
			switch(channel,
				9, {port.put($Q)},
				10, {port.put($W)},
				11, {port.put($E)},
				12, {port.put($R)},
				13, {port.put($T)},
				14, {port.put($Y)},
				15, {port.put($U)},
				16, {port.put($I)},
				{port.put(channel.asDigit)}
			);
			port.put(powerDown.clip(0, 1).asDigit);
			port.put(gain.clip(0, 6).asDigit);
			port.put(type.clip(0, 7).asDigit);
			port.put(bias.clip(0, 1).asDigit);
			port.put(srb2.clip(0, 1).asDigit);
			port.put(srb1.clip(0, 1).asDigit);
			port.put($X);
		}, {
			"channel % out of range".format(channel).warn;
		});
	}
	maximumChannelNumber {|channels= 16|
		switch(channels,
			8, {port.put($c)},
			16, {port.put($C)},
			{"channels can only be 8 or 16".warn}
		);
	}

	//--private
	prTask {  //TODO
		var last3= [0, 0, 0];
		var buffer= List(32);
		var state= 0;
	}
}
