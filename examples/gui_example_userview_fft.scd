//fft gui example with userview / pen graphics

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match you board
//var board= CytonWifi(NetAddr("192.168.1.103", 13999), initAction: {|b| b.start});
var width= 640, height= 640;
var chanHeight= height/board.numChannels;
var win, usr, f;
win= Window("fft gui example userview", Rect(100, 100, width, height)).front;
usr= UserView(win, Rect(0, 0, width, height));
usr.animate= true;
usr.frameRate= 60;
usr.background= Color.black;
usr.clearOnRefresh= false;
usr.drawFunc= {
	var x= usr.frame%width;
	var h= height/board.numChannels/f.fft[0].size;
	//f.fft.postln;  //debug
	f.fft.do{|arr, cy|
		arr.do{|val, y|
			Pen.fillColor= Color.grey(val);
			Pen.fillRect(Rect(x, (cy+1*chanHeight)-y, 1, h));
		};
	};
};
f= OpenBCIfft(board, 250);
f.start;
CmdPeriod.doOnce({win.close});
~openbci= board;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
