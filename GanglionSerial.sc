//--supercollider openbci ganglion biosensing board (4-channels), communication via serial (bluetooth dongle)

GanglionSerial : Ganglion {
	var <port, task;

	*new {|port, baudrate= 115200, dataAction, replyAction, initAction|
		^super.new(dataAction, replyAction, initAction).initGanglionSerial(port, baudrate);
	}
	initGanglionSerial {|argPort, argBaudrate|
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
		var buffer= List(20);
		var state= 0;
		var reply, num, aux= (26..31);
		0.1.wait;

		//TODO unfinished
		inf.do{|i|
			var byte= port.read;
			//byte.postln;  //debug
			buffer.add(byte);
			switch(state,
				0, {
					if(byte==0, {  //packet id
						if(buffer.size>1, {
							buffer= List(20);
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
							if(reply.contains("OpenBCI Ganglion"), {
								initAction.value(reply);
							});
							replyAction.value(reply);
							buffer= List(20);
						});
					});
				},
				1, {
					if(buffer.size>=20, {
						state= 2;
					});
				},
				2, {
					buffer.postln;
					buffer= List(20);
					state= 0;
				}
			);
		};
	}
}
