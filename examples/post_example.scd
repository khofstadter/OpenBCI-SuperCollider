//very simple example - just posting

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match you board
//var board= CytonWifi(NetAddr("192.168.1.103", 13999), initAction: {|b| b.start});
board.dataAction= {|...args| args.postln};
~openbci= board;
)

~openbci.softReset;
~openbci.start;
SerialPort.listDevices;

//note: specially when using wifi and a high samplerate, posting every data package can flood the post window and crash supercollider.
//use the following to reduce the amout of data being posted - e.g. only post every 50th package.
~openbci.dataAction= {|num, data, aux, stop| if(num%50==0, {data.postln})};

//normalize electrode data and post
~openbci.dataAction= {|num, data, aux, stop| if(num%50==0, {(data/(2**23-1)).postln})};

//normalize and post latest decoded accelerometer data
~openbci.dataAction= {|num, data, aux, stop| if(num%50==0, {(~openbci.accel/(2**15-1)).postln})};

~openbci.close;
