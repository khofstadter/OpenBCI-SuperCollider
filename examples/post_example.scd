//very simple example - just posting

SerialPort.listDevices;

(
var board= Cyton;  //edit here to match you board e.g. Ganglion
var port= "/dev/tty.OpenBCI-DM00DRM0";  //edit
~openbci= board.new(port, dataAction:{|...args| args.postln}, initAction:{~openbci.start});
)

~openbci.softReset;
~openbci.start;

//normalize electrode data and post
~openbci.dataAction= {|num, data, aux, stop| (data/(2**23-1)).postln};

//normalize and post latest decoded accelerometer data
~openbci.dataAction= {|num, data, aux, stop| (~openbci.accel/(2**15-1)).postln};
