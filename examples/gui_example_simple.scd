//simple gui example just displaying raw data using sliders and numberboxes

(
var board= CytonSerial("/dev/tty.usbserial-DM00DRM0", initAction: {|b| b.start});  //edit here to match your board
//var board= CytonWifi(NetAddr("OpenBCI_WifiShieldOSC.local", 13999), initAction: {|b| b.start});
//var board= SyntheticData(initAction: {|b| b.start});  //synthetic test data
//var board= PlaybackData("~/Desktop/OpenBCI-RAW-2019-04-10_19-04-26.txt", initAction: {|b| b.start});  //file data
var lastValues= -1.dup(board.numChannels);
var lastTime= 0;
var win, sliders, numbers;
~maxuV= 1000;
win= Window("gui example simple", Rect(100, 100, 80*board.numChannels, 240)).front;
sliders= {Slider().canFocus_(false)}.dup(board.numChannels);
numbers= {NumberBox().canFocus_(false)}.dup(board.numChannels);
win.layout= VLayout(*[
	HLayout(*sliders),
	HLayout(*numbers)
]);
board.dataAction= {|num, data, aux, stop|
	if(Main.elapsedTime-lastTime>0.033, {  //downsample to 30fps
		lastTime= Main.elapsedTime;
		data.do{|x, i|
			if(x!=lastValues[i], {  //filter out repeats
				lastValues[i]= x;
				{
					sliders[i].value= x.linlin(0-~maxuV, ~maxuV, 0, 1);  //-500 to 500uV
					numbers[i].value= x;  //display raw values
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
