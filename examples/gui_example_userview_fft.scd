//fft gui example with userview / pen graphics

SerialPort.listDevices;

(
var board= Cyton;  //edit here to match you board e.g. Ganglion
var port= "/dev/tty.OpenBCI-DM00DRM0";  //edit
var width= 640, height= 480;
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
~openbci= board.new(port, initAction:{~openbci.start});
f= OpenBCIfft(~openbci, 250);
f.start;
CmdPeriod.doOnce({win.close});
)

~openbci.softReset;
~openbci.start;
