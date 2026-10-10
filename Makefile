BUILD_DIR := build
PRESET := debug
CMAKE := cmake
QEMU := qemu-system-x86_64

QEMU_FLAGS := -machine pc -m 128M

ifeq ($(FULL_SCREEN),1)
QEMU_DISPLAY := -display cocoa,full-screen=on,zoom-to-fit=on
else
QEMU_DISPLAY := -display cocoa,zoom-to-fit=on
endif

BOOT_BIN := $(BUILD_DIR)/artifacts/boot.bin
KERNEL_ELF := $(BUILD_DIR)/artifacts/kernel.elf
FLOPPY_IMG := $(BUILD_DIR)/artifacts/sOS.img

.PHONY: all configure build boot kernel run debug check clean distclean help floppy inspect-floppy

all: build

configure:
	$(CMAKE) --preset $(PRESET)

build: configure
	$(CMAKE) --build --preset $(PRESET)

boot: configure
	$(CMAKE) --build $(BUILD_DIR) --target bootsector

kernel: configure
	$(CMAKE) --build $(BUILD_DIR) --target kernel.elf

floppy: configure
	$(CMAKE) --build $(BUILD_DIR) --target floppy

inspect-floppy: floppy
	file $(BUILD_DIR)artifacts/sOS.img
	mdir -i $(BUILD_DIR)artifacts/sOS.img ::

check:
	@test -f "$(BOOT_BIN)" || { echo "Errore: boot sector non trovato"; exit 1; }
	@test "$$(wc -c < "$(BOOT_BIN)" | tr -d ' ')" = "512" || { echo "Errore: boot sector diverso da 512 byte"; exit 1; }
	@echo "Boot sector OK (512 byte)"
	@if [ -f "$(KERNEL_ELF)" ]; then file "$(KERNEL_ELF)"; else echo "Kernel ELF non ancora generato"; fi

run: build check floppy
	$(QEMU) $(QEMU_FLAGS) $(QEMU_DISPLAY) -drive format=raw,if=floppy,file="$(FLOPPY_IMG)"
	# $(QEMU) $(QEMU_FLAGS) $(QEMU_DISPLAY) -drive format=raw,file="$(BOOT_BIN)"

debug: build check floppy
	# $(QEMU) $(QEMU_FLAGS) $(QEMU_DISPLAY) -drive format=raw,file="$(BOOT_BIN)" -S -s
	$(QEMU) $(QEMU_FLAGS) $(QEMU_DISPLAY) -drive format=raw,if=floppy,file="$(FLOPPY_IMG)" -S -s

clean:
	$(CMAKE) --build $(BUILD_DIR) --target clean


distclean:
	rm -rf "$(BUILD_DIR)"

help:
	@echo "sOS - comandi disponibili"
	@echo "  make / make build  Configura e compila il progetto"
	@echo "  make configure     Configura CMake"
	@echo "  make boot          Compila il boot sector"
	@echo "  make kernel        Compila il kernel"
	@echo "  make check         Verifica gli artefatti"
	@echo "  make run           Avvia il boot sector in QEMU"
	@echo "  make debug         Avvia QEMU in attesa di GDB"
	@echo "  make clean         Pulisce gli artefatti di compilazione"
	@echo "  make distclean     Elimina tutta la directory build"
	@echo "  make help          Mostra questo messaggio"
