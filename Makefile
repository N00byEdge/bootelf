.PHONY: all clean
.SECONDARY:;

default: all

NASM ?= nasm
CC ?= gcc
LD ?= ld

ifeq (3.81,$(MAKE_VERSION))
$(error Error: apple make is not supported! Use gmake from homebrew instead)
endif

define TestTemplate =
$(1)/%.o: $(1)/%.asm Makefile
	nasm $$< -o $$@ -felf64

$(1)/%.o: $(1)/%.c Makefile
	$(CC) $$< -c -o $$@ -e _start

$(1)/%.elf: $(1)/%.o Makefile
	$(LD) $$< -o $$@

$(1)/%.bin: bootelf $(1)/%.elf Makefile
	cat $$^ > $$@
	truncate -s '%512' $$@

tname := $$(word 2,$$(subst /, ,$(1)))
tests := $$(tests) tests/$$(tname)/$$(tname).bin
endef

$(foreach test, $(shell find tests -maxdepth 1 -mindepth 1),$(eval $(call TestTemplate,$(test))))

all: $(tests)
	printf "%s\n" $(tests) | \
		xargs -n 1 -I diskhere -- \
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

bootelf: bootelf.asm framebuffer.asm elf_load.asm memmap.asm paging.asm
	nasm $< -o $@
