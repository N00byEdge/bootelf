all: tests/a/a.bin  tests/c/c.bin tests/dump/dump.bin
	echo -n $^ | xargs -n 1 -d ' ' -I diskhere -- qemu-system-x86_64 $(QEMUFlags) -drive format=raw,file=diskhere -debugcon stdio -no-reboot -s

.PHONY: all clean
.SECONDARY:;

clean:
	rm -v bootelf       || true
	rm -v tests/*/*.bin || true
	rm -v tests/*/*.elf || true
	rm -v tests/*/*.o   || true

define TestTemplate =
$(1)/%.o: $(1)/%.asm Makefile
	nasm $$< -o $$@ -felf64

$(1)/%.o: $(1)/%.c Makefile
	gcc $$< -c -o $$@ -e _start

$(1)/%.elf: $(1)/%.o Makefile
	ld $$< -o $$@

$(1)/%.bin: bootelf $(1)/%.elf Makefile
	cat $$^ > $$@
	 truncate -s '%512' $$@
endef

$(foreach test, $(shell find tests -maxdepth 1 -mindepth 1),$(eval $(call TestTemplate,$(test))))

bootelf: bootelf.asm
	nasm $< -o $@
