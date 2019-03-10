//very simple example - just posting

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b| b.start});
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
~openbci.dataAction= {|num, data, aux, stop| if(num%50==0, {data.linlin(-8388608, 8388607, -1, 1).postln})};

//normalize and post latest decoded accelerometer data
~openbci.dataAction= {|num, data, aux, stop| if(num%50==0, {~openbci.accel.linlin(-32768, 32767, -1, 1).postln})};

~openbci.close;
