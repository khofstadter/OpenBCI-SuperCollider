//--abstract class for supercollider openbci communication

//related: Cyton Ganglion CytonSerial GanglionSerial CytonWifi GanglionWifi

OpenBCI {
	var <>dataAction, <>replyAction, <>initAction;  //callback functions
	var <>accelAction;  //more callback functions
	var <>data, <>accel;  //latest readings (can be nil)
	var <buffer;  //history readings
	var <numChannels, <currentSampleRate;
	*new {|dataAction, replyAction, initAction|
		^super.new.init(dataAction, replyAction, initAction);
	}
	init {|argDataAction, argReplyAction, argInitAction|

		//--default actions
		dataAction= argDataAction;
		replyAction= argReplyAction ? {|reply| reply.postln};
		initAction= argInitAction;

		numChannels= this.class.numChannels;
		currentSampleRate= this.class.defaultSampleRate;
		buffer= {List.fill(5750, {0})}.dup(numChannels);
		("%: starting...").format(this.class.name).postln;
	}
	updateBuffer {|data|
		buffer.do{|buf, i|
			buf.removeAt(0);
			buf.add(data[i]);
		};
	}

	//--commands
	off {|channel= 1|  //Turn Channels OFF
		channel.asArray.do{|c|
			if(c>=1 and:{c<=numChannels}, {
				switch(c,
					1, {this.prCommand($1)},
					2, {this.prCommand($2)},
					3, {this.prCommand($3)},
					4, {this.prCommand($4)},
					5, {this.prCommand($5)},
					6, {this.prCommand($6)},
					7, {this.prCommand($7)},
					8, {this.prCommand($8)},
					9, {this.prCommand($q)},
					10, {this.prCommand($w)},
					11, {this.prCommand($e)},
					12, {this.prCommand($r)},
					13, {this.prCommand($t)},
					14, {this.prCommand($y)},
					15, {this.prCommand($u)},
					16, {this.prCommand($i)}
				);
			}, {
				"channel % not in the range 1-%".format(c, numChannels).warn;
			});
		};
	}
	on {|channel= 1|  //Turn Channels ON
		channel.asArray.do{|c|
			if(c>=1 and:{c<=numChannels}, {
				switch(c,
					1, {this.prCommand($!)},
					2, {this.prCommand($@)},
					3, {this.prCommand($#)},
					4, {this.prCommand($$)},
					5, {this.prCommand($%)},
					6, {this.prCommand($^)},
					7, {this.prCommand($&)},
					8, {this.prCommand($*)},
					9, {this.prCommand($Q)},
					10, {this.prCommand($W)},
					11, {this.prCommand($E)},
					12, {this.prCommand($R)},
					13, {this.prCommand($T)},
					14, {this.prCommand($Y)},
					15, {this.prCommand($U)},
					16, {this.prCommand($I)}
				);
			}, {
				"channel % not in the range 1-%".format(c, numChannels).warn;
			});
		};
	}

	startLogging {|time= '5MIN'|  //initiate sd card data logging for specified time
		switch(time,
			'5MIN', {this.prCommand($A)},
			'15MIN', {this.prCommand($S)},
			'30MIN', {this.prCommand($F)},
			'1HR', {this.prCommand($G)},
			'2HR', {this.prCommand($H)},
			'4HR', {this.prCommand($J)},
			'12HR', {this.prCommand($K)},
			'24HR', {this.prCommand($L)},
			'14SEC', {this.prCommand($a)},
			{"time % not recognised".format(time).warn}
		);
	}
	stopLogging {  //stop logging data and close sd file
		this.prCommand($j);
	}

	start {  //start streaming data
		this.prCommand($b);
	}
	stop {  //stop streaming data
		this.prCommand($s);
	}
	query {
		this.prCommand($?);  //query register settings
	}
	softReset {
		this.prCommand($v);  //soft reset for the board peripherals
		currentSampleRate= this.class.defaultSampleRate;
	}

	attachWifi {
		this.prCommand(${);
	}
	removeWifi {
		this.prCommand($});
	}
	getWifiStatus {
		this.prCommand($:);
	}
	softResetWifi {
		this.prCommand($;);
	}

	//--private
	prCommand {|cmd| ^this.subclassResponsibility(thisMethod)}
	prCommandArray {|arr| ^this.subclassResponsibility(thisMethod)}

	prSyntheticData {
		var amp1= 10*2.sqrt, amp2= 50*2.sqrt;
		var thetas= (0.0).dup(numChannels);
		var atheta= 0.0;
		var aux= [0, 0, 0];  //TODO
		var lastTime= 0, deltaTime;
		initAction.value(this, "init synthetic data");
		data= 0.dup(numChannels);
		inf.do{|num|
			numChannels.do{|i|
				//TODO deal with muted channels here?
				var val= 0.gauss(1)*(currentSampleRate/2).sqrt;
				switch(i,
					0, {
						val= val*10;
					},
					1, {
						val= val+(amp1*sin(thetas[i]*2pi*10));
						thetas[i]= thetas[i]+(1/currentSampleRate);
					},
					2, {
						val= val+(amp2*sin(thetas[i]*2pi*50));
						thetas[i]= thetas[i]+(1/currentSampleRate);
					},
					3, {
						val= val+(amp2*sin(thetas[i]*2pi*60));
						thetas[i]= thetas[i]+(1/currentSampleRate);
					}
				);
				data[i]= (val/this.uVScale(24)).round*this.uVScale(24);  //TODO deal with gain changes
			};

			deltaTime= Main.elapsedTime-lastTime;
			if(deltaTime>=0.04, {  //25Hz
				accel= {|j| (sin(atheta*2pi/3.75+(j*0.5pi))*32767).asInteger*this.accScale}.dup(3);
				accelAction.value(accel);
				atheta= atheta+deltaTime;
				lastTime= Main.elapsedTime;
			});

			this.updateBuffer(data);
			dataAction.value(num.asInteger%256, data, aux, 0);  //TODO should set aux and byte too for accelerometer

			(1/currentSampleRate).wait;
		};
	}
}
