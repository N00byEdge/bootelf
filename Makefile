.PHONY: all clean
.SECONDARY:;

default: all

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

tname := $$(word 2,$$(subst /, ,$(1)))
tests := $$(tests) tests/$$(tname)/$$(tname).bin
endef

$(foreach test, $(shell find tests -maxdepth 1 -mindepth 1),$(eval $(call TestTemplate,$(test))))

all: $(tests)
	echo -n $^ | \
		xargs -n 1 -d ' ' -I diskhere -- \
		qemu-system-x86_64\
			$(QEMUFlags)\
			-drive format=raw,file=diskhere\
			-debugcon stdio\
			-no-reboot\
			-s

clean:
	rm -v bootelf       || true
	rm -v tests/*/*.bin || true
	rm -v tests/*/*.elf || true
	rm -v tests/*/*.o   || true

bootelf: bootelf.asm framebuffer.asm elf_load.asm memmap.asm
	nasm $< -o $@
