//gui example with userview / pen graphics
//only plotting accelerometer data

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= CytonTest(initAction: {|b| b.start});
var buffer= OpenBCIbuf(board, 100, false, true);
var width= 640, height= 320;
var win, usr, x= 0;
buffer.start;
win= Window("gui example userview accelerometer", Rect(10, 100, width, height)).front;
usr= UserView(win, Rect(0, 0, width, height));
usr.animate= true;
usr.frameRate= 60;
usr.background= Color.white;
usr.clearOnRefresh= false;
usr.drawFunc= {
	buffer.readAccel.do{|xyz|
		Pen.fillColor= Color.white;
		Pen.fillRect(Rect(x, 0, 1, height));
		Pen.fillColor= Color.grey(0.9);
		Pen.fillRect(Rect(0, 0, 100, 70));
		Pen.fillColor= Color.red;
		Pen.stringAtPoint("x:"+xyz[0], Point(5, 5));
		Pen.fillRect(Rect(x, xyz[0].linlin(-4.096, 4.096, height, 0), 1, 1));
		Pen.fillColor= Color.green;
		Pen.stringAtPoint("y:"+xyz[1], Point(5, 25));
		Pen.fillRect(Rect(x, xyz[1].linlin(-4.096, 4.096, height, 0), 1, 1));
		Pen.fillColor= Color.blue;
		Pen.stringAtPoint("z:"+xyz[2], Point(5, 45));
		Pen.fillRect(Rect(x, xyz[2].linlin(-4.096, 4.096, height, 0), 1, 1));
		x= x+1%width;
	};
};
CmdPeriod.doOnce({win.close});
~openbci= board;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
