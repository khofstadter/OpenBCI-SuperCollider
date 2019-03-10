//--supercollider openbci ganglion biosensing board (4-channels), generate dummy synthetic test data

GanglionTest : Ganglion {
	var task;

	*new {|dummy1, dummy2, dataAction, replyAction, initAction|
		^super.new(dataAction, replyAction, initAction).initGanglionTest;
	}
	initGanglionTest {
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
