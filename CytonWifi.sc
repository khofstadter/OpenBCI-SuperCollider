//--supercollider openbci cyton biosensing board (8-channels) communication via osc (wifi shield)

CytonWifi : Cyton {
	var <netAddr, responders, num, aux= #[26, 27, 28, 29, 30, 31];

	*new {|netAddr, reset= true, dataAction, replyAction, initAction|
		^super.new(dataAction, replyAction, initAction).initCytonWifi(netAddr, reset);
	}
	initCytonWifi {|argNetAddr, argReset|
		netAddr= argNetAddr ?? {NetAddr("OpenBCI_WifiShieldOSC.local", 13999)};
		CmdPeriod.add(this);
		if(argReset, {this.softReset});
		responders= List[
			OSCFunc({|msg, time, addr, port| initAction.value(this, addr)}, \ready, netAddr),
			OSCFunc({|msg| replyAction.value(msg[1..].join(Char.space))}, \reply, netAddr),
			OSCFunc({|msg| msg[1].postln}, \version, netAddr),
			OSCFunc({|msg| msg[1].postln}, \name, netAddr),
			OSCFunc({|msg| msg[1].postln}, \board, netAddr),
			OSCFunc({|msg| msg[1].postln}, \all, netAddr),
			OSCFunc({|msg|
				var buffer, byte, numByte;
				(msg.size-1).do{|i|
					buffer= msg[i+1];
					byte= 256+buffer[0];
					if(byte>=0xC0 and:{byte<=0xCF}, {  //check valid footer
						numByte= buffer[1];
						if(numByte&128>0, {
							numByte= 256+numByte;
						});
						if(num.notNil and:{numByte-1%256!=num}, {
							"dropped package % %".format(numByte, num).warn;
						});
						num= numByte;
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
				};
			}, \data, netAddr)
		];
	}
	ip_ {|str|
		netAddr.sendMsg(\ip, *str.split($.).asInteger);
	}
	port_ {|val|
		netAddr.sendMsg(\port, val);
	}
	latency_ {|val|
		netAddr.sendMsg(\latency, val.max(0));
	}
	name {
		netAddr.sendMsg(\name);
	}
	version {
		netAddr.sendMsg(\version);
	}
	board {
		netAddr.sendMsg(\board);
	}
	all {
		netAddr.sendMsg(\all);
	}
	close {
		"%: stopping and removing osc responders".format(this.class.name).postln;
		this.stop;
		responders.do{|x| x.free};
		responders= List.new;
		CmdPeriod.remove(this);
	}
	cmdPeriod {
		this.close;
	}

	//--private
	prCommand {|cmd| netAddr.sendMsg(\command, cmd.asString)}
	prCommandArray {|cmd|
		var str;
		if(cmd.isString, {
			netAddr.sendMsg(\command, cmd);
		}, {
			str= String.newClear(cmd.size);
			cmd.do{|a, i| str[i]= if(a<0, {256+a}, {a}).asAscii};
			netAddr.sendMsg(\command, str);
		});
	}
}


CytonDaisyWifi : CytonWifi {
	//TODO
}
