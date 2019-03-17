//--supercollider openbci cyton biosensing board (8-channels), generate dummy synthetic test data

CytonTest : Cyton {
	var task, >warn= true;

	*new {|dummy1, dummy2, dataAction, replyAction, initAction|
		^super.new(dataAction, replyAction, initAction).initCytonTest;
	}
	initCytonTest {
		CmdPeriod.add(this);
		task= Routine({this.prTask}).play(SystemClock);
	}
	close {
		"%: stopping synthetic test data".format(this.class.name).postln;
		task.stop;
		CmdPeriod.remove(this);
	}
	cmdPeriod {
		this.close;
	}

	//--private
	prCommand {|cmd| }
	prCommandArray {|cmd| }
	prTask {^this.prSyntheticData}
}

CytonDaisyTest : CytonTest {
	classvar <numChannels= 16;
}
