//--supercollider openbci generate dummy synthetic test data

SyntheticData : OpenBCI {
	classvar <numChannels= 8;
	classvar <defaultSampleRate= 250;
	var task, muted;
	uVScale {|gain= 24| ^4.5/gain/(2**23-1)*1000000}
	accScale {^0.002/(2**4)}

	*new {|numChannels= 8, sampleRate= 250, dataAction, initAction, bufferSize= 512|
		^super.new(dataAction, nil, initAction, bufferSize).initSyntheticData(numChannels, sampleRate);
	}
	initSyntheticData {|argNumChannels, argSampleRate|
		currentSampleRate= argSampleRate;
		numChannels= argNumChannels;
		buffer= {List.fill(bufferSize, {0})}.dup(numChannels);  //need to recreate buffer because numChannels is nil
		muted= false.dup(numChannels);

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

	off {|channel= 1|
		muted.clipPut(channel-1, true);
	}
	on {|channel= 1|
		muted.clipPut(channel-1, false);
	}

	//--private
	prTask {
		var thetas= (0.0).dup(numChannels);
		var atheta= 0.0;
		var aux= [0, 0, 0];  //TODO
		var lastTime= 0, deltaTime;
		data= 0.dup(numChannels);
		inf.do{|num|
			numChannels.do{|i|
				var val;
				if(muted[i].not, {
					val= 0.gauss(1)*(currentSampleRate/2).sqrt;
					switch(i,
						0, {
							val= val*10;
						},
						1, {
							val= val+(10*2.sqrt*sin(thetas[i]*2pi*10));
							thetas[i]= thetas[i]+(1/currentSampleRate);
						},
						2, {
							val= val+(20*2.sqrt*sin(thetas[i]*2pi*15));
							thetas[i]= thetas[i]+(1/currentSampleRate);
						},
						3, {
							val= val+(30*2.sqrt*sin(thetas[i]*2pi*20));
							thetas[i]= thetas[i]+(1/currentSampleRate);
						},
						4, {
							val= val+(40*2.sqrt*sin(thetas[i]*2pi*25));
							thetas[i]= thetas[i]+(1/currentSampleRate);
						},
						5, {
							val= val+(50*2.sqrt*sin(thetas[i]*2pi*30));
							thetas[i]= thetas[i]+(1/currentSampleRate);
						},
						6, {
							val= val+(20*2.sqrt*sin(thetas[i]*2pi*60));
							thetas[i]= thetas[i]+(1/currentSampleRate);
						}
					);
					data[i]= (val/this.uVScale(24)).round*this.uVScale(24);  //TODO deal with gain changes
				});
			};

			deltaTime= Main.elapsedTime-lastTime;
			if(deltaTime>=0.04, {  //25Hz
				accel= {|j| (sin(atheta*2pi/3.75+(j*0.5pi))*32767).asInteger*this.accScale}.dup(3);
				accelAction.value(accel);
				atheta= atheta+deltaTime;
				lastTime= Main.elapsedTime;
			}, {
				accel= #[0.0, 0.0, 0.0];
			});

			this.updateBuffer(data);
			dataAction.value(num.asInteger%256, data, accel);

			(1/currentSampleRate).wait;
		};
	}
}
