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
	var <gains, <state= 0, <buffer;
	*new {|port, dataAction, replyAction, initAction|
		^super.new(port).initCyton(dataAction, replyAction, initAction);
	}
	initCyton {|argDataAction, argReplyAction, argInitAction|

		//--default actions
		dataAction= argDataAction;
		replyAction= argReplyAction ? {|reply| reply.postln};
		initAction= argInitAction;

		//--startup
		("% starting...").format(this.class.name).postln;
		this.softReset;
		gains= 24!numChannels;

		//--read loop
		task= Routine({
			var last3= [0, 0, 0];
			//var buffer= List(32);
			var num, aux= (26..31);
			var reply;
			buffer= List(32);
			inf.do{|i|
				var byte= port.read;
				//byte.postln;  //debug
				buffer.add(byte);
				switch(state,
					0, {
						if(byte==0xA0, {  //header
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
									gains= 24!numChannels;
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
						if(byte>=0xC0 and:{byte<=0xCF}, {  //footer
							num= buffer[1];  //sample number
							data= Array.fill(numChannels, {|i|  //eight channels of 24bit data
								var msb= buffer[i*3+2];
								var pre= 0;
								if(msb&128>0, {
									pre= -0x01000000;
								});
								pre+(msb<<16)+(buffer[i*3+3]<<8)+buffer[i*3+4];
							});
							data= data*(4.5/gains/(2**23-1));  //channel data scale factor
							if(byte==0xC0 and:{aux.any{|i| buffer[i]!=0}}, {
								accel= Array.fill(3, {|i|  //three dimensions of 16bit data
									var msb= buffer[i*2+26];
									var pre= 0;
									if(msb&128>0, {
										pre= -0x010000;
									});
									pre+(msb<<8)+buffer[i*2+27];
								});
								accel= accel*(0.002/(2**4));  //accelerometer scale factor
							});
							dataAction.value(num, data, accel);
							//TODO: parse aux data depending on footer
						}, {
							("% read error").format(this.class.name).postln;
						});
						buffer= List(32);
						state= 0;
					}
				);
			};
		}).play(SystemClock);
	}

	//--commands
	off {|channel= 1|  //Turn Channels OFF
		channel.asArray.do{|c|
			switch(c,
				1, {port.put($1)},
				2, {port.put($2)},
				3, {port.put($3)},
				4, {port.put($4)},
				5, {port.put($5)},
				6, {port.put($6)},
				7, {port.put($7)},
				8, {port.put($8)},
				{"channel % not in the range 1-8".format(c).warn}
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
				5, {port.put($%)},
				6, {port.put($^)},
				7, {port.put($&)},
				8, {port.put($*)},
				{"channel % not in the range 1-8".format(c).warn}
			);
		};
	}

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
			switch(gain,
				0, {gains[channel-1]= 1},
				1, {gains[channel-1]= 2},
				2, {gains[channel-1]= 4},
				3, {gains[channel-1]= 6},
				4, {gains[channel-1]= 8},
				5, {gains[channel-1]= 12},
				6, {gains[channel-1]= 24}
			);
		}, {
			"channel % out of range".format(channel).warn;
		});
	}
	setDefaultChannelSettings {  //set all channels to default
		port.put($d);
		gains= 24!numChannels;
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

	timeStamping {|on= true|
		if(on, {
			port.put($<);
		}, {
			port.put($>);
		});
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

	attachWifi {
		port.put(${);
	}
	removeWifi {
		port.put($});
	}
	getWifiStatus {
		port.put($:);
	}
	softResetWifi {
		port.put($;);
	}

	getVersion {  //get firmware version
		port.put($V);
	}
}

CytonDaisy : Cyton {
	classvar <numChannels= 16;
	off {|channel= 1|  //Turn Channels OFF
		channel.asArray.do{|c|
			switch(c,
				1, {port.put($1)},
				2, {port.put($2)},
				3, {port.put($3)},
				4, {port.put($4)},
				5, {port.put($5)},
				6, {port.put($6)},
				7, {port.put($7)},
				8, {port.put($8)},
				9, {port.put($q)},
				10, {port.put($w)},
				11, {port.put($e)},
				12, {port.put($r)},
				13, {port.put($t)},
				14, {port.put($y)},
				15, {port.put($u)},
				16, {port.put($i)},
				{"channel % not in the range 1-16".format(c).warn}
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
				5, {port.put($%)},
				6, {port.put($^)},
				7, {port.put($&)},
				8, {port.put($*)},
				9, {port.put($Q)},
				10, {port.put($W)},
				11, {port.put($E)},
				12, {port.put($R)},
				13, {port.put($T)},
				14, {port.put($Y)},
				15, {port.put($U)},
				16, {port.put($I)},
				{"channel % not in the range 1-16".format(c).warn}
			);
		};
	}
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
			switch(gain,
				0, {gains[channel-1]= 1},
				1, {gains[channel-1]= 2},
				2, {gains[channel-1]= 4},
				3, {gains[channel-1]= 6},
				4, {gains[channel-1]= 8},
				5, {gains[channel-1]= 12},
				6, {gains[channel-1]= 24}
			);
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
}
