a [Quark](http://supercollider-quarks.github.io/quarks/) for [SuperCollider](http://supercollider.github.io)

# OpenBCI
SuperCollider classes for communicating with [Open Brain Computer Interface](http://openbci.com).

The following boards are supported...

* Cyton (8 channels) [overview](https://shop.openbci.com/collections/frontpage/products/cyton-biosensing-board-8-channel?variant=38958638542), [docs](http://docs.openbci.com/Hardware/02-Cyton), [sdk](http://docs.openbci.com/OpenBCI%20Software/04-OpenBCI_Cyton_SDK)

* Cyton + Daisy (16 channels) **untested** [overview](https://shop.openbci.com/collections/frontpage/products/cyton-daisy-biosensing-boards-16-channel?variant=38959256526)

* Ganglion (4 channels) [overview](https://shop.openbci.com/collections/frontpage/products/pre-order-ganglion-board?variant=13461804483), [docs](http://docs.openbci.com/Hardware/07-Ganglion), [sdk](http://docs.openbci.com/OpenBCI%20Software/06-OpenBCI_Ganglion_SDK)

```supercollider
//install
Quarks.fetchDirectory
Quarks.install("OpenBCI-SuperCollider")
//recompile
OpenBCI.openHelpFile
```

for more info see http://openbci.com

## overview

* Cyton, CytonDaisy, Ganglion - use these SuperCollider classes if you connect to your board via bluetooth serial (the dongle). Maximum sample rate is 250Hz (Cyton) and 200Hz (Ganglion).

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
