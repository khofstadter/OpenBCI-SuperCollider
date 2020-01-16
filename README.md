a [Quark](http://supercollider-quarks.github.io/quarks/) for [SuperCollider](http://supercollider.github.io)

# OpenBCI
SuperCollider classes for communicating with [Open Source Brain-Computer Interfaces](http://openbci.com).

The following boards are supported...

* [Cyton](https://shop.openbci.com/collections/frontpage/products/cyton-biosensing-board-8-channel?variant=38958638542) (8 channels) [docs](http://docs.openbci.com/Hardware/02-Cyton), [sdk](http://docs.openbci.com/OpenBCI%20Software/04-OpenBCI_Cyton_SDK)

* [Cyton + Daisy](https://shop.openbci.com/collections/frontpage/products/cyton-daisy-biosensing-boards-16-channel?variant=38959256526) (16 channels) **untested**

* [Ganglion](https://shop.openbci.com/collections/frontpage/products/pre-order-ganglion-board?variant=13461804483) (4 channels) [docs](http://docs.openbci.com/Hardware/07-Ganglion), [sdk](http://docs.openbci.com/OpenBCI%20Software/06-OpenBCI_Ganglion_SDK)

```supercollider
//install
Quarks.fetchDirectory
Quarks.install("OpenBCI-SuperCollider")
//recompile
OpenBCI.openHelpFile
```

For more info see http://openbci.com

## overview

* Cyton, CytonDaisy, Ganglion - use these SuperCollider classes if you connect to your board via bluetooth serial (the dongle). Maximum sample rate is 250Hz (Cyton) and 200Hz (Ganglion).

* CytonWifi, CytonDaisyWifi, GanglionWifi - these SuperCollider classes require the [WiFi Shield](https://shop.openbci.com/collections/frontpage/products/wifi-shield?variant=44534009550) (also [DIY](https://www.fredrikolofsson.com/f0blog/?q=node/664)) and a special firmware ( [Arduino sketch](https://github.com/redFrik/OpenBCI_WIFI/blob/OpenSoundControl/examples/WifiShieldOSC/WifiShieldOSC.ino) ) for sending OSC. Maximum sample rate for these classes is 16000Hz.

* PlaybackData - is a class tha can play back recorded data from file (e.g. the files recorded onto the onboard SD-card).

* SyntheticData - with this class you generate synthetic test data. No hardware board needed.

* DataFilterNotch, DataFilterBandpass, DataSmoothing, DataFFT, DataRecord etc - these are classes for analysing and modifying data.

![screenshot-openbci](screenshot-openbci.png?raw=true "OpenBCI-screenshot")
_(screenshot showing gui widgets ported from OpenBCI_GUI.app)_

## troubleshooting

**mac os 10.12.x** and later with cyton + dongle...

if you experience freezes and sporadic updates in the stream of serial data, make sure that you are using the AppleUSBFTDI driver and *not* the driver from ftdichip.com.
to check plug in the dongle, open terminal and type...
```
kextstat | grep FTDI
```
if it is reporting `com.FTDI.driver.FTDIUSBSerialDriver (2.4.2)` then unload this driver with the following terminal command...
```
sudo kextunload -b com.FTDI.driver.FTDIUSBSerialDriver
```
unplug and plug in the dongle and once again run...
```
kextstat | grep FTDI
```
it should now report `com.apple.driver.AppleUSBFTDI (5.0.0)` and the data should come streaming in at a smooth rate and without hickups. test this with for example the file `gui_example_userview_accelerometer.scd`.

**mac os 10.11.x** and earlier with cyton + dongle...
if hickups and freezes see here... http://docs.openbci.com/Tutorials/10-Mac_FTDI_Driver_Fix

## changelog

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
* DataFFT - add different fft window types
* converter class for SD log file data
* ganglion impedance
