//--abstract class for supercollider openbci communication

OpenBCI {
	var <port, task;
	var <>dataAction, <>replyAction, <>initAction;  //callback functions
	var <>data, <>accel;  //latest readings (can be nil)
	*new {|port, baudrate= 115200|
		^super.new.initOpenBCI(port, baudrate);
	}
	initOpenBCI {|argPort, argBaudrate|
		port= SerialPort(argPort ? "/dev/tty.usbserial-DJ00DO0N", argBaudrate, crtscts:true);
		CmdPeriod.doOnce({port.close});
	}
	close {
		task.stop;
		port.close;
	}

	//--commands
	startLogging {|time= '5MIN'|  //initiate sd card data logging for specified time
		switch(time,
			'5MIN', {port.put($A)},
			'15MIN', {port.put($S)},
			'30MIN', {port.put($F)},
			'1HR', {port.put($G)},
			'2HR', {port.put($H)},
			'4HR', {port.put($J)},
			'12HR', {port.put($K)},
			'24HR', {port.put($L)},
			'14SEC', {port.put($a)},
			{"time % not recognised".format(time).warn}
		);
	}
	stopLogging {  //stop logging data and close sd file
		port.put($j);
	}
	start {  //start streaming data
		port.put($b);
	}
	stop {  //stop streaming data
		port.put($s);
	}
	query {
		port.put($?);  //query register settings
	}
	softReset {
		port.put($v);  //soft reset for the board peripherals
	}
}
