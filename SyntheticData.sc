//--supercollider openbci generate dummy synthetic test data

SyntheticData : OpenBCI {
	classvar <defaultSampleRate= 250;
	var task;
	uVScale {|gain= 24| ^4.5/gain/(2**23-1)*1000000}
	accScale {^0.002/(2**4)}

	*new {|numChannels= 8, sampleRate= 250, dataAction, initAction, bufferSize= 1024|
		^super.new(dataAction, nil, initAction, bufferSize).initSyntheticData(numChannels, sampleRate);
	}
	initSyntheticData {|argNumChannels, argSampleRate|
		currentSampleRate= argSampleRate;
		numChannels= argNumChannels;
		buffer= {List.fill(bufferSize, {0})}.dup(numChannels);  //need to recreate buffer because numChannels is nil

		initAction.value(this, "init synthetic data");
		CmdPeriod.add(this);
	}
	start {
		task.stop;
		task= Routine({this.prTask}).play(SystemClock);
	}
	stop {
		"%: stopping synthetic test data".format(this.class.name).postln;
		task.stop;
		CmdPeriod.remove(this);
	}
	softReset {
		currentSampleRate= this.class.defaultSampleRate;
	}
	close {
		this.stop;
	}
	cmdPeriod {
		this.stop;
	}

	//--private
	prTask {
		var amp1= 10*2.sqrt, amp2= 50*2.sqrt;
		var thetas= (0.0).dup(numChannels);
		var atheta= 0.0;
		var aux= [0, 0, 0];  //TODO
		var lastTime= 0, deltaTime;
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
