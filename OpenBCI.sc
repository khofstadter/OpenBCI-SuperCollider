//--abstract class for supercollider openbci communication

//related: OpenBCIboard Cyton Ganglion CytonSerial GanglionSerial CytonWifi GanglionWifi

OpenBCI {
	classvar numChannels;
	var <>dataAction, <>replyAction, <>initAction;  //callback functions
	var <>accelAction;  //more callback functions
	var <>data, <>accel;  //latest readings (can be nil)
	var <bufferSize;  //number of readings to keep in history
	var <buffer;  //history
	var <currentSampleRate;
	var >warn= true;
	*new {|dataAction, replyAction, initAction, bufferSize= 512|
		^super.new.initOpenBCI(dataAction, replyAction, initAction, bufferSize);
	}
	initOpenBCI {|argDataAction, argReplyAction, argInitAction, argBufferSize|

		//--default actions
		dataAction= argDataAction;
		replyAction= argReplyAction ? {|reply| reply.postln};
		initAction= argInitAction;

		currentSampleRate= this.class.defaultSampleRate;

		bufferSize= argBufferSize;
		buffer= {List.fill(bufferSize, {0})}.dup(this.class.numChannels);
		("%: starting...").format(this.class.name).postln;
	}
	numChannels {^this.class.numChannels}
	bufferSize_ {|size= 512|
		bufferSize= size.asInteger;
		buffer= buffer.collect{|data|
			data= data.asArray.extend(bufferSize, 0).asList;
		};
	}
	updateBuffer {|data|
		buffer.do{|buf, i|
			buf.removeAt(0);
			buf.add(data[i]);
		};
	}
	start {^this.subclassResponsibility(thisMethod)}
	stop {^this.subclassResponsibility(thisMethod)}
	softReset {^this.subclassResponsibility(thisMethod)}
}
