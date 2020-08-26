all: tests/a/a.bin
	qemu-system-x86_64 -drive format=raw,file=$< -s -S -d int

.PHONY: all clean
.SECONDARY:;

clean:
	rm -v bootelf       || true
	rm -v tests/*/*.bin || true
	rm -v tests/*/*.elf || true
	rm -v tests/*/*.o   || true

define TestTemplate =
$(1)/%.o: $(1)/%.asm
	nasm $$< -o $$@ -felf64

$(1)/%.elf: $(1)/%.o
	ld $$< -o $$@

$(1)/%.bin: bootelf $(1)/%.elf
	cat $$^ > $$@
	 truncate -s '%512' $$@
endef

$(foreach test, $(shell find tests -maxdepth 1 -mindepth 1),$(eval $(call TestTemplate,$(test))))

bootelf: bootelf.asm
	nasm $< -o $@
