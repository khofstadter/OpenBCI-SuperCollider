//very simple example - just posting

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
board.dataAction= {|num, data, accel| if(num%50==0, {data.postln})};  //only post every 50th package (uV)
~openbci= board;
)

//note: specially when using wifi and a high samplerate, posting every data package can flood the post window and crash supercollider.
~openbci.dataAction= {|num, data, accel| if(num%10==0, {data.postln})};  //only post every 10th package
~openbci.dataAction= nil;

//post latest decoded accelerometer data (-4g to 4g)
~openbci.accelAction= {|xyz| xyz.postln};  //post everything. possible because internally only 25hz

~openbci.close;


~openbci.softReset;
~openbci.start;
SerialPort.listDevices;
