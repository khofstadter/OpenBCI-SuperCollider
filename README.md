a [Quark](http://supercollider-quarks.github.io/quarks/) for [SuperCollider](http://supercollider.github.io)

# OpenBCI
SuperCollider classes for communicating with [Open Brain Computer Interface](http://openbci.com).

* Cyton (8 channels) [overview](https://shop.openbci.com/collections/frontpage/products/cyton-biosensing-board-8-channel?variant=38958638542) [docs](http://docs.openbci.com/Hardware/02-Cyton) [sdk](http://docs.openbci.com/OpenBCI%20Software/04-OpenBCI_Cyton_SDK)

* Cython + Daisy (16 channels) **untested** [overview](https://shop.openbci.com/collections/frontpage/products/cyton-daisy-biosensing-boards-16-channel?variant=38959256526)

* Ganglion (4 channels) [overview](https://shop.openbci.com/collections/frontpage/products/pre-order-ganglion-board?variant=13461804483) [docs](http://docs.openbci.com/Hardware/07-Ganglion) [sdk](http://docs.openbci.com/OpenBCI%20Software/06-OpenBCI_Ganglion_SDK)

```supercollider
//install
Quarks.fetchDirectory
Quarks.install("OpenBCI-SuperCollider")
//recompile
OpenBCI.openHelpFile
```

for more info see http://openbci.com
