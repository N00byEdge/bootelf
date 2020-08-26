# Bootelf
Want to make your kernel elf file bootable?

Just append your elf to this boot sector and you will boot straight into it.

## Details
* Interrupts are disabled
* Bottom 1G is identity mapped
* Your elf file is loaded at `0x7E00`.
* You get nothing from the bios, but who needs a memory map?
* Any memory below `0x7E00` should not be touched unless you've stopped
using the bootloaders page tables and GDT
