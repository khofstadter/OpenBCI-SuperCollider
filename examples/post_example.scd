//very simple example - just posting

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b| b.start});
board.dataAction= {|num, data, aux, stop| if(num%50==0, {data.postln})};  //only post every 50th package (uV)
~openbci= board;
)

//note: specially when using wifi and a high samplerate, posting every data package can flood the post window and crash supercollider.
~openbci.dataAction= {|num, data, aux, stop| if(num%10==0, {data.postln})};  //only post every 10th package

//post latest decoded accelerometer data (-4g to 4g)
~openbci.dataAction= {|num, data, aux, stop| if(num%50==0, {~openbci.accel.postln})};

~openbci.close;


~openbci.softReset;
~openbci.start;
SerialPort.listDevices;
