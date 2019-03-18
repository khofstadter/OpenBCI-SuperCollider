//fft gui example with userview / pen graphics

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b| b.start});
var width= 640, height= 256;
var win, usr, f;
~channel= 2;  //which channel to read
win= Window("fft gui example userview", Rect(100, 100, width, height)).front;
usr= UserView(win, Rect(0, 0, width, height));
usr.animate= true;
usr.frameRate= 60;
usr.background= Color.black;
usr.clearOnRefresh= false;
usr.drawFunc= {
	var x= usr.frame%width;
	var d= f.fft(~channel);
	//d.postln;  //debug
	d.drop(1).do{|val, y|
		Pen.fillColor= Color.grey(val.explin(0.1, 200, 0, 1));  //0.1-200 uV
		Pen.fillRect(Rect(x, y.linlin(0, f.fftSize*0.5, height, 0), 1, 1));
	};
};
f= OpenBCIfft(board, 512);
f.start;
CmdPeriod.doOnce({win.close});
~openbci= board;
)

~openbci.addFilter(DataFilterNotch('50'));

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
~channel= 1;
~channel= 2;
~openbci.setSampleRate(3)
