//--supercollider openbci cyton biosensing board (8-channels) communication via osc (wifi shield)

CytonWifi : Cyton {
	var <netAddr, responders, num, aux= #[26, 27, 28, 29, 30, 31], >warn= true;

	*new {|netAddr, reset= true, dataAction, replyAction, initAction, bufferSize= 1024|
		^super.new(dataAction, replyAction, initAction, bufferSize).initCytonWifi(netAddr, reset);
	}
	initCytonWifi {|argNetAddr, argReset|
		netAddr= argNetAddr ?? {NetAddr("OpenBCI_WifiShieldOSC.local", 13999)};
		CmdPeriod.add(this);
		if(argReset, {this.softReset});
		responders= List[
			OSCFunc({|msg, time, addr, port|
				"% shield ready (%)".format(this.class.name, addr.ip).postln;
				initAction.value(this, addr);
			}, \ready, netAddr),
			OSCFunc({|msg| replyAction.value(msg[1..].join(Char.space))}, \reply, netAddr),
			OSCFunc({|msg| msg[1].postln}, \version, netAddr),
			OSCFunc({|msg| msg[1].postln}, \name, netAddr),
			OSCFunc({|msg| msg[1].postln}, \board, netAddr),
			OSCFunc({|msg| msg[1].postln}, \all, netAddr),
			OSCFunc({|msg|
				var buffer, byte;
				(msg.size-1).do{|i|
					buffer= msg[i+1].collect{|x| if(x<0, {256+x}, {x})};
					byte= buffer[0];
					if(byte>=0xC0 and:{byte<=0xCF}, {  //check valid footer
						if(warn and:{num.notNil and:{buffer[1]-1%256!=num}}, {
							"% dropped package(s) % %".format(this.class.name, num, buffer[1]).warn;
						});
						num= buffer[1];  //sample number
						data= Array.fill(numChannels, {|i|  //eight channels of 24bit data converted to uV
							var v= (buffer[i*3+2]<<16)|(buffer[i*3+3]<<8)|buffer[i*3+4];
							if((v&0x800000)>0, {v|0xFF000000}, {v&0x00FFFFFF})*this.uVScale(24);  //TODO deal with gain changes
						});
						switch(byte,  //footer / stop byte
							0xC0, {  //accelerometer
								if(aux.any{|i| buffer[i]!=0}, {
									accel= Array.fill(3, {|i|  //three dimensions of 16bit data converted to g
										var v= (buffer[i*2+26]<<8)|buffer[i*2+27];
										if((v&0x8000)>0, {v|0xFFFF0000}, {v&0x0000FFFF})*this.accScale;
									});
									accelAction.value(accel);
								});
							};
						);
						this.updateBuffer(data);
						dataAction.value(num, data, buffer[aux], byte);
					}, {
						buffer.postln;
						("% read error").format(this.class.name).postln;
					});
				};
			}, \data, netAddr)
		];
		netAddr.sendMsg(\reset);
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
	classvar <numChannels= 16;
	//TODO
}
