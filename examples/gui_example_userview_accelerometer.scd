//gui example with userview / pen graphics
//only plotting accelerometer data

SerialPort.listDevices;

(
var width= 640, height= 320;
var win, usr;
win= Window("gui example userview accelerometer", Rect(100, 100, width, height)).front;
usr= UserView(win, Rect(0, 0, width, height));
usr.animate= true;
usr.frameRate= 60;
usr.background= Color.white;
usr.clearOnRefresh= false;
usr.drawFunc= {
	var x= usr.frame%width;
	var ax, ay, az;
	Pen.fillColor= Color.white;
	Pen.fillRect(Rect(x, 0, 1, height));
	Pen.fillColor= Color.grey(0.9);
	Pen.fillRect(Rect(0, 0, 70, 70));
	if(~openbci.accel.notNil, {
		Pen.fillColor= Color.red;
		ax= ~openbci.accel[0];
		Pen.stringAtPoint("x:"+ax, Point(5, 5));
		Pen.fillRect(Rect(x, ax.linlin(-32767, 32767, height, 0), 1, 1));
		Pen.fillColor= Color.green;
		ay= ~openbci.accel[1];
		Pen.stringAtPoint("y:"+ay, Point(5, 25));
		Pen.fillRect(Rect(x, ay.linlin(-32767, 32767, height, 0), 1, 1));
		Pen.fillColor= Color.blue;
		az= ~openbci.accel[2];
		Pen.stringAtPoint("z:"+az, Point(5, 45));
		Pen.fillRect(Rect(x, az.linlin(-32767, 32767, height, 0), 1, 1));
	});
};
~openbci= Cyton("/dev/tty.OpenBCI-DM00DRM0", initAction:{~openbci.start});  //edit
CmdPeriod.doOnce({win.close});
)

~openbci.softReset;
~openbci.start;