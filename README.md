# Particle Operational System (2019)

> Bare-bones Operating System written in **x86 Assembly Language**.


## How to build
> * ### `Windows`
>> * Download [flat assembler 1](http://flatassembler.net/download.php) for **Windows**
>> * Build with <code> fasm/fasm.exe Particle/src/Disk.asm </code>

> * ### `Linux (untested)`
>> * Download [flat assembler 1](http://flatassembler.net/download.php) for **Linux**
>> * Build with <code> fasm/fasm.exe Particle/src/Disk.asm </code>

> * ### `Andrioid`
>> * Download [flat assembler 1](http://flatassembler.net/download.php) for **DOS**
>> * Download [DosBox Turbo](https://play.google.com/store/apps/details?id=com.fishstix.dosbox) for **Android**
>> * Open DosBox and build with <code> fasm/fasm.exe Particle/src/Disk.asm </code>


## How to test
> * ### `Windows (untested)`
>> * Download any **x86-64 PC Emulator** (Bochs, QEMU, VirtualBox, Virtual PC, VMware, ...) for **Windows**
>> * Follow the manual to know how to create a new x86-64 machine insert the *Virtual Floppy Disk* `Particle/src/Disk.img` and *boot* from

> * ### `Linux (untested)`
>> * Download any **x86-64 PC Emulator** (Bochs, QEMU, VirtualBox, VMware, ...) for **Linux**
>> * Follow the manual to know how to create a new x86-64 machine insert the *Virtual Floppy Disk* `Particle/src/Disk.img` and *boot* from

> * ### `Android`
>> * Download [**Limbo x86 PC Emulator**](https://github.com/limboemu/limbo/wiki/Downloads)
>> * Select `New` in option `Load Machine`
>> * Enter a new name for your new machine
>> * Click on `CREATE`
>> * Click on `CANCEL`
>> * Go to section `CPU Board`
>> * Select `x64` in option `Architecture`
>> * Select at minimum `8` in option `RAM Memory (MB)`
>> * Go to section `Removable`
>> * Mark the option `Floppy A`
>> * Select `Open` in option `Floppy A`
>> * Find and chose the file `Particle/src/Disk.img` on your phone storage
>> * Go to section `Boot`
>> * Select `Floppy` in option `Boot from Device`
>> * Press the button Start (Play symbol) to initialize the system


## Special Thanks
*"I want to thanks these `companies`, `communities` and/or `persons` for their amazing `work` and `help`, they made the development of this system something possible. Thank you very much!"* - `David Reis`


> [Intel](https://www.intel.com) - Developers of **x86 Architecture**, which created the basis of Personal Computers.

> [AMD](https://www.amd.com) - Developers of **x86-64 Architecture**, in which this system is based.

> [Tomasz Grysztar and his Community](https://board.flatassembler.net) - Developers of **fasm** used for compile the source code.

> [OSDev Community](https://wiki.osdev.com) - Developers of **Wiki OSDev**, which created amazing guides for Operating System Development.

> [Fishstix](http://dosboxturbo.priorityencoding.com) - Developers of **DosBox Turbo**, used to run *fasm for DOS*.

> [Limbo Emu](https://github.com/limboemu/limbo/wiki) - Developers of **Limbo x86 PC Emulator**, used for emulate the system.

> [Rhythm Software](https://rhmsoft.com) Developers of **QuickEdit**, used for create the source code.

















































