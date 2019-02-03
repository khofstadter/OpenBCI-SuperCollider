//--supercollider openbci cyton biosensing board (8-channels), communication via serial (bluetooth dongle)

CytonSerial : Cyton {
	var <port, task, >warn= true;

	*new {|port, baudrate= 115200, dataAction, replyAction, initAction|
		^super.new(dataAction, replyAction, initAction).initCytonSerial(port, baudrate);
	}
	initCytonSerial {|argPort, argBaudrate|
		port= SerialPort(argPort ? "/dev/tty.OpenBCI-DM00DRM0", argBaudrate, crtscts:true);
		CmdPeriod.add(this);
		this.softReset;
		task= Routine({this.prTask}).play(SystemClock);
	}
	close {
		"%: stopping and closing serial port".format(this.class.name).postln;
		task.stop;
		port.close;
		CmdPeriod.remove(this);
	}
	cmdPeriod {
		this.close;
	}

	//--private
	prCommand {|cmd| port.put(cmd)}
	prCommandArray {|cmd| port.putAll(cmd)}
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
							if(buffer[0]==65, {  //TODO remove this when openbci fixes firmware upstream
								buffer= buffer.drop(32);
								//"temp fix applied".postln;  //debug
							});
							reply= "";
							(buffer.size-3).do{|i| reply= reply++buffer[i].asAscii};
							if(reply.contains("OpenBCI V3 8-16 channel"), {
								initAction.value(this, reply);
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
						if(warn and:{num.notNil and:{buffer[1]-1%256!=num}}, {
							"% dropped package(s) % %".format(this.class.name, num, buffer[1]).warn;
						});
						num= buffer[1];  //sample number
						data= Array.fill(numChannels, {|i|  //eight channels of 24bit data
							var v= (buffer[i*3+2]<<16)|(buffer[i*3+3]<<8)|buffer[i*3+4];
							if((v&0x800000)>0, {v|0xFF000000}, {v&0x00FFFFFF});
						});
						switch(byte,  //footer / stop byte
							0xC0, {  //accelerometer
								if(aux.any{|i| buffer[i]!=0}, {
									accel= Array.fill(3, {|i|  //three dimensions of 16bit data
										var v= (buffer[i*2+26]<<8)|buffer[i*2+27];
										if((v&0x8000)>0, {v|0xFFFF0000}, {v&0x0000FFFF});
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

CytonDaisySerial : CytonSerial {

	//--private
	prTask {  //TODO
		var last3= [0, 0, 0];
		var buffer= List(32);
		var state= 0;
	}
}
