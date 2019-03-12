//very simple example - just posting

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b| b.start});
board.dataAction= {|num, data, aux, stop| if(num%50==0, {data.postln})};  //only post every 50th package
~openbci= board;
)

//note: specially when using wifi and a high samplerate, posting every data package can flood the post window and crash supercollider.
~openbci.dataAction= {|num, data, aux, stop| if(num%10==0, {data.postln})};  //only post every 10th package

//normalize electrode data and post
~openbci.dataAction= {|num, data, aux, stop| if(num%50==0, {data.linlin(-8388608, 8388607, -1, 1).postln})};

//normalize and post latest decoded accelerometer data
~openbci.dataAction= {|num, data, aux, stop| if(num%50==0, {~openbci.accel.linlin(-32768, 32767, -1, 1).postln})};

~openbci.close;


~openbci.softReset;
~openbci.start;
SerialPort.listDevices;
