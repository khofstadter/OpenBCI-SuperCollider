//--abstract class for supercollider openbci communication

//related: Cyton Ganglion

OpenBCI {
	var <port, task;
	var <>dataAction, <>replyAction, <>initAction;  //callback functions
	var <>accelAction;  //more callback functions
	var <>data, <>accel;  //latest readings (can be nil)
	*new {|port, baudrate= 115200, dataAction, replyAction, initAction|
		^super.new.initOpenBCI(port, baudrate, dataAction, replyAction, initAction);
	}
	initOpenBCI {|argPort, argBaudrate, argDataAction, argReplyAction, argInitAction|
		port= SerialPort(argPort ? "/dev/tty.OpenBCI-DM00DRM0", argBaudrate, crtscts:true);
		CmdPeriod.doOnce({port.close});

		//--default actions
		dataAction= argDataAction;
		replyAction= argReplyAction ? {|reply| reply.postln};
		initAction= argInitAction;

		//--startup
		("% starting...").format(this.class.name).postln;
		this.softReset;

		//--read loop
		task= Routine({this.prTask}).play(SystemClock);
	}
	close {
		task.stop;
		port.close;
	}

	//--commands
	off {|channel= 1|  //Turn Channels OFF
		channel.asArray.do{|c|
			if(c>=1 and:{c<=this.class.numChannels}, {
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
					16, {port.put($i)}
				);
			}, {
				"channel % not in the range 1-%".format(c, this.class.numChannels).warn;
			});
		};
	}
	on {|channel= 1|  //Turn Channels ON
		channel.asArray.do{|c|
			if(c>=1 and:{c<=this.class.numChannels}, {
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
					16, {port.put($I)}
				);
			}, {
				"channel % not in the range 1-%".format(c, this.class.numChannels).warn;
			});
		};
	}

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

	prTask {^this.subclassResponsibility(thisMethod)}
}
