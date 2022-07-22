a [Quark](https://supercollider-quarks.github.io/quarks/) for [SuperCollider](https://supercollider.github.io)

main author: [redFrik](https://github.com/redFrik)

# OpenBCI
SuperCollider classes for communicating with [Open Source Brain-Computer Interfaces](https://openbci.com).

The following boards are supported...

* [Cyton](https://docs.openbci.com/Cyton/CytonLanding/) (8 channels) [sdk](https://docs.openbci.com/Cyton/CytonSDK/)

* [Cyton + Daisy](https://docs.openbci.com/Cyton/CytonSpecs/#openbci-daisy-module) (16 channels) **untested**

* [Ganglion](https://docs.openbci.com/Ganglion/GanglionLanding/) (4 channels), [sdk](https://docs.openbci.com/Ganglion/GanglionSDK/)

```supercollider
//install
Quarks.fetchDirectory
Quarks.install("OpenBCI-SuperCollider")
//recompile
OpenBCI.openHelpFile
```

For more info see https://openbci.com

Note that several of the examples here are ported from the official application [OpenBCI_GUI](https://docs.openbci.com/Software/OpenBCISoftware/GUIDocs/) v4.2.0.

## overview

* Cyton, CytonDaisy, Ganglion - use these SuperCollider classes if you connect to your board via bluetooth serial (the dongle). Maximum sample rate is 250Hz (Cyton) and 200Hz (Ganglion).

* CytonWifi, CytonDaisyWifi, GanglionWifi - these SuperCollider classes require the [WiFi Shield](https://docs.openbci.com/ThirdParty/WiFiShield/WiFiLanding/) (also [DIY](https://fredrikolofsson.com/f0blog/openbci-wifi-shield-diy/)) and a special firmware ( [Arduino sketch](https://github.com/redFrik/OpenBCI_WIFI/blob/OpenSoundControl/examples/WifiShieldOSC/WifiShieldOSC.ino) ) for sending OSC. Maximum sample rate for these classes is 16000Hz.

* PlaybackData - is a class tha can play back recorded data from file (e.g. the files recorded onto the onboard SD-card).

* SyntheticData - with this class you generate synthetic test data. No hardware board needed.

* DataFilterNotch, DataFilterBandpass, DataSmoothing, DataFFT, DataRecord etc - these are classes for analysing and modifying data.

![screenshot-openbci](screenshot-openbci.png?raw=true "OpenBCI-screenshot")
_(screenshot showing gui widgets ported from OpenBCI_GUI.app)_

## troubleshooting

see https://docs.openbci.com/Troubleshooting/TroubleshootingLanding/

## changelog

* 1.82 - fft optimisation and windowtypes, fixing links, increase framerate in examples
* 1.81 - important bugfix for recorded/raw data file playback
* 1.80 - default bufferSize reduced from 1024 to 512, filters now calculate in place, use Image class
* 1.75 - added three scsynth examples and fixed some outdated links
* 1.71 - phase coherence added to -8ch nf, nf_plotter.scd added (with audio player and 'PlayFile' folder)
* 1.70 - neurofeedback-2ch and -8ch added
* 1.63 - impedance tests and examples, autoscale accelerometer
* 1.62 - readme updates with screenshot
* 1.61 - bugfix, remove wifi reset argument, simplify focus widget example
* 1.60 - file recording class, changed dataAction arguments
* 1.53 - file playback class
* 1.52 - focus widget
* 1.51 - bugfix for numChannels that made most examples stop working
* 1.50 - renamed buf, fft, lag, seq, test classes and added OpenBCIboard, bandpower widget
* 1.40 - rewrote filters and OpenBCIfft again, bufferSize, added OpenBCIlag, fixed examples
* 1.30 - rewrote filters and OpenBCIfft, added internal board buffer, fixed examples
* 1.20 - added filter functionality and classes, scaling inside classes, many example fixes
* 1.13 - ported some openbci_gui widgets, added tests, currentSampleRate, active flags
* 1.12 - added new sequencer class, buffer class stop bugfix, fixed examples
* 1.11 - added new buffer class
* 1.10 - big fixes to fft, clean up examples
* 1.02 - changed to direct ip instead of broadcast - need latest WifiShieldOSC
* 1.01 - improved helpfile, added initAction feedback, new advanced example
* 1.00 - big breaking rewrite and restructure of classes, added osc wifi classes

## todo

* are getRadioChannel, setRadioChannel, setRadioHostChannel, getRadioPollTime, setRadioPollTime, setRadioHostBaudRate, getRadioSystemStatus, attachWifi, removeWifi supposed to work with wifishield?
* document all methods in Cyton, CytonDaisy and Ganglion classes
* add a 10sec timeout on initAction
* implement and test the different aux commands
* finish and test Ganlion classes - both serial and wifi
* finish and test Daisy classes - both serial and wifi
* deal with muted channels in test and fft classes
* converter class for SD log file data
* ganglion impedance
