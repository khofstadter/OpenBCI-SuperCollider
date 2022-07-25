//gui example with userview / pen graphics
//only plotting accelerometer data

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
//var recorder= DataRecord(board).start;  //uncomment to record
var buffer= DataBuffer(board, 100, false, true);
var width= 640, height= 320;
var win, img, imgFunc, x= 0, data;
var colors= [Color.red, Color.green, Color.blue], clear= Color.clear;
var lastPosition= {Point(0, 0)}!3;
buffer.start;
win= Window("gui example userview accelerometer", Rect(10, 100, width, height)).front;
win.view.background= Color.white;
img= Image(width, height);
imgFunc= {
	img.draw({
		data.do{|xyz|
			height.do{|y| img.setColor(clear, x, y)};
			xyz.do{|val, i|
				Pen.strokeColor= colors[i];
				y= val.linlin(-4.096, 4.096, height, 0);
				Pen.line(lastPosition[i], Point(x, y));
				Pen.stroke;
				lastPosition[i].x= x%(width-1);
				lastPosition[i].y= y;
			};
			x= x+1%width;
		};
	});
};
win.drawFunc= {
	Pen.drawImage(Rect(0, 0, win.bounds.width, win.bounds.height), img);
	Pen.fillColor= Color.grey(0.9, 0.7);
	Pen.fillRect(Rect(0, 0, 100, 70));
	data.do{|xyz|
		Pen.fillColor= colors[0];
		Pen.stringAtPoint("x:"+xyz[0], Point(5, 5));
		Pen.fillColor= colors[1];
		Pen.stringAtPoint("y:"+xyz[1], Point(5, 25));
		Pen.fillColor= colors[2];
		Pen.stringAtPoint("z:"+xyz[2], Point(5, 45));
	};
};
win.onClose= {img.free; board.stop};
CmdPeriod.doOnce({win.close});

Routine({
	var nextTime;
	while({win.isClosed.not}, {
		nextTime= Main.elapsedTime+(1/60);
		data= buffer.readAccel;
		if(data.isEmpty.not, {
			imgFunc.value;
			win.refresh;
		});
		(nextTime-Main.elapsedTime).max(0.001).wait;
	});
}).play(AppClock);

~openbci= board;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
