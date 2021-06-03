# Bootelf
Want to make your kernel elf file bootable?

Just append your elf to this boot sector and you will boot straight into it.

## Details
* Interrupts are disabled
* Bottom 2G is identity mapped at virtaddr 0, top half base and -2G
* Your elf file is loaded at `0x7E00`.
* Any memory below `0x7E00` should not be touched unless you've stopped using the bootloaders page tables, structures (including memory map!) and GDT
* You will get a `Bootelf_data *` passed in `rdi` (first argument in any sensible calling convention):
    ```c
    struct Bootelf_data {
      u64 magic; // == 0xb00731f, read as bootelf
      u64 numEntries;
      struct Bootelf_memmap_entry *entries;
      struct Bootelf_framebuffer framebuffer;
    };

    // 32 bpp framebuffer
    struct Bootelf_framebuffer {
      u64 base;
      u32 pitch;
      u32 width;
      u32 height;
    };
    
    struct Bootelf_memmap_entry {
      u64 base;
      u64 size;
      u32 type;
      u32 acpi3type;
    };
    ```
    `Bootelf_memmap_entry` directly corresponds to the values aquired from a E820 memory map, and should be interpreted as such. Note that the framebuffer might be unmapped. If the `base` field in the framebuffer struct is `0`, bootelf was unable to get you a framebuffer, and the standard VESA text mode will be active.
