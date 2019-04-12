//--supercollider openbci ganglion biosensing board (4-channels) communication via osc (wifi shield)

GanglionWifi : Ganglion {
	var <netAddr, responders;

	*new {|netAddr, reset= true, dataAction, replyAction, initAction, bufferSize= 1024|
		^super.new(dataAction, replyAction, initAction, bufferSize).initGanglionWifi(netAddr, reset);
	}
	initGanglionWifi {|argNetAddr, argReset|
		netAddr= argNetAddr ?? {NetAddr("OpenBCI_WifiShieldOSC.local", 13999)};
		CmdPeriod.add(this);
		if(argReset, {this.softReset});
		responders= List[
			OSCFunc({|msg, time, addr, port|
				"% shield ready (%)".format(this.class.name, addr.ip).postln;
				initAction.value(this, addr);
				accel= #[0.0, 0.0, 0.0];
			}, \ready, netAddr),
			OSCFunc({|msg| replyAction.value(msg[1..].join(Char.space))}, \reply, netAddr),
			OSCFunc({|msg| msg[1].postln}, \version, netAddr),
			OSCFunc({|msg| msg[1].postln}, \name, netAddr),
			OSCFunc({|msg| msg[1].postln}, \board, netAddr),
			OSCFunc({|msg| msg[1].postln}, \all, netAddr),
			OSCFunc({|msg| /* TODO */ }, \data, netAddr)
		];
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
