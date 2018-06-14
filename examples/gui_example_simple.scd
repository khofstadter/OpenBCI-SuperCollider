//simple gui example just displaying data using sliders and numberboxes
(
var board= Cyton;  //edit here to match you board e.g. Ganglion
var port= "/dev/tty.OpenBCI-DM00DRM0";  //edit
var lastValues= -1.dup(board.numChannels);
var lastTime= 0;
var win, sliders, numbers, updateFunc;
win= Window("gui example simple", Rect(100, 100, 75*board.numChannels, 240)).front;
sliders= {Slider().canFocus_(false)}.dup(board.numChannels);
numbers= {NumberBox().canFocus_(false)}.dup(board.numChannels);
win.layout= VLayout(*[
	HLayout(*sliders),
	HLayout(*numbers)
]);
updateFunc= {|num, data, aux, stop|
	if(data.notNil, {
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
	});
};
~openbci= board.new(port, dataAction: updateFunc, initAction:{~openbci.start});
CmdPeriod.doOnce({win.close});
)

~openbci.softReset;
~openbci.start;
