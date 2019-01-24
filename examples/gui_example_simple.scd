//simple gui example just displaying data using sliders and numberboxes

(
var board= CytonSerial("/dev/tty.OpenBCI-DM00DRM0", initAction: {|b| b.start});  //edit here to match you board
//var board= CytonWifi(NetAddr("192.168.1.103", 13999), initAction: {|b| b.start});
var lastValues= -1.dup(board.numChannels);
var lastTime= 0;
var win, sliders, numbers;
win= Window("gui example simple", Rect(100, 100, 75*board.numChannels, 240)).front;
sliders= {Slider().canFocus_(false)}.dup(board.numChannels);
numbers= {NumberBox().canFocus_(false)}.dup(board.numChannels);
win.layout= VLayout(*[
	HLayout(*sliders),
	HLayout(*numbers)
]);
board.dataAction= {|num, data, aux, stop|
	if(Main.elapsedTime-lastTime>0.016, {  //downsample to 60fps
		lastTime= Main.elapsedTime;
		data.do{|x, i|
			if(x!=lastValues[i], {  //filter out repeats
				lastValues[i]= x;
				{
					sliders[i].value= x.linlin(-8388607, 8388607, 0, 1);
					numbers[i].value= x;
				}.defer;
			});
		};
	});
};
CmdPeriod.doOnce({win.close});
~openbci= board;
)

~openbci.softReset;
~openbci.start;
~openbci.stop;
SerialPort.listDevices;
