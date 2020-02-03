//plotter by khofstadter
//TODO plotting raw data (we would need the whole resolution)

/*

--columns in raw EEG file
#0 index (0-255)
#1-8 ch1-ch8 raw data
#9-11 accelorometre (not used)
#12-19 ch1-ch8 (bandEnergyAvg for selected bands)
#20 nf-threshold
#21 ~phaseCalcFuncVal (phase coherence between two ~bandEnergyAvg e.g. ~bandEnergyAvg[6] and ~bandEnergyAvg[7])
#22 ~phaseCalcFuncVal (phase coherence between two ~bandEnergyAvg e.g. ~bandEnergyAvg[5] and ~bandEnergyAvg[6])
#23 timestamp1 (e.g: 11:02:46.832)
#24 timestamp2 (e.g: 1569492166832)
*/

//--plotter and audio player
(
var limiter= 5;
var alphaColor= 100;
var plotterA, plotterB;
var datasetA, datasetB;
var colors= [
	Color.new255(129, 129, 129),
	Color.new255(124, 75, 141, alphaColor),
	Color.new255(54, 87, 158, alphaColor),
	Color.new255(49, 113, 89, alphaColor),
	Color.new255(221, 178, 13, alphaColor),
	Color.new255(253, 94, 52, alphaColor),
	Color.new255(224, 56, 45, alphaColor),
	Color.new255(162, 82, 49, alphaColor)
];
var window= Window.new("Plotter Example", Rect(0,0,1024,600)).front;
window.view.layout_(VLayout(
	//the plotters
	(plotterA= Plotter("PlotterA",nil,View())).interactionView.minSize_(500@150).canFocus_(false),
	(plotterB= Plotter("PlotterB",nil,View())).interactionView.minSize_(500@150).canFocus_(false),
));

//ADD YOUR FILE:
//(need to reboot interpreter in case new file is plotted)
if(x.isKindOf(Array).not, {
	x= CSVFileReader.read("/Users/khofstadter/Library/Application Support/SuperCollider/downloaded-quarks/OpenBCI-SuperCollider/savedData/OpenBCI-RAW-2020-02-03_13-39-32_sc.txt".standardizePath;);
	6.do{x.removeAt(0)};
});


p= 0 ! (x.size/255) ! 16;

a= 0;
b= 0;
c= 0;
d= 0 ! 20;
e= 0;

x.size.do{|i|
	if (x[i][0] == "0",
		{
			p[0][a]= x[i][12].asFloat.min(limiter); //bandEnergyAvg[0]
			p[1][a]= x[i][13].asFloat.min(limiter); //bandEnergyAvg[1]
			p[2][a]= x[i][14].asFloat.min(limiter);
			p[3][a]= x[i][15].asFloat.min(limiter);
			p[4][a]= x[i][16].asFloat.min(limiter);
			p[5][a]= x[i][17].asFloat.min(limiter);
			p[6][a]= x[i][18].asFloat.min(limiter);
			p[7][a]= x[i][19].asFloat.min(limiter); //bandEnergyAvg[7]

			p[12][a]= x[i][20].asFloat; //threshold

			p[13][a]= x[i][21].asFloat.min(1); //~phaseCalcFuncVal[0]
			p[14][a]= x[i][22].asFloat.min(1); //~phaseCalcFuncVal[1]

			a= a+1;
		}
	);
}.value;

p[15]= 1 ! p[0].size; //constant horizontal line to indicate max. coherence (+1)

//--the datasets to visualize

datasetA= [
	p[1],
	p[12]
];

datasetB= [
	p[6],p[7],p[5],
	p[13],p[14],
	p[15]
];

//--load datasets and customise plotters
plotterA.value_(datasetA); //load dataset
plotterA.plotMode= \linear;
plotterA.superpose_(true); //allow channels overlay
plotterA.setProperties( //customize appearence
	\plotColor, [
		colors[0],
		Color.new255(205, 92, 92)
	], //plot colors
	\backgroundColor, Color.white, //background color
	\gridColorX, Color.grey, //gridX color
	//\gridColorY, Color.yellow, //gridY color
	\gridOnX, true, //horizontal grid
	\gridOnY, false //vertical grid
);

plotterB.value_(datasetB);
plotterB.plotMode= \linear;
plotterB.superpose_(true);
plotterB.setProperties(
	\plotColor, [
		colors[6],colors[7],colors[5],
		Color.new255(0, 100, 0, 200),Color.new255(0, 200, 0, 200),
		Color.black
	],
	\backgroundColor, Color.white,
	\gridColorX, Color.grey,
	//\gridColorY, Color.yellow,
	\gridOnX, true,
	\gridOnY, false
);
)