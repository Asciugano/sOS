cmake_minimum_required(VERSION 3.25)

project(sOS
    VERSION 0.1.0
    LANGUAGES C ASM ASM_NASM
)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)

set(SOS_ARTIFACTS_DIR "${CMAKE_BINARY_DIR}/artifacts")

add_subdirectory(boot)
add_subdirectory(kernel)

find_program(OBJCOPY_EXECUTABLE x86_64-elf-objcopy REQUIRED)

set(SOS_KERNEL_ELF "${CMAKE_BINARY_DIR}/kernel/kernel.elf")
set(SOS_KERNEL_BIN "${SOS_ARTIFACTS_DIR}/kernel.bin")
set(SOS_BOOT_SECTOR "${SOS_ARTIFACTS_DIR}/boot.bin")

add_custom_command(
    OUTPUT "${SOS_KERNEL_BIN}"

    COMMAND "${OBJCOPY_EXECUTABLE}"
        -O binary
        "${SOS_KERNEL_ELF}"
        "${SOS_KERNEL_BIN}"

    DEPENDS "${SOS_KERNEL_ELF}"

    COMMENT "Converting kernel ELF to flat binary"
    VERBATIM
)

add_custom_target(kernel-bin
    DEPENDS "${SOS_KERNEL_BIN}"
)

add_dependencies(kernel-bin kernel.elf)

find_program(MKFS_FAT_EXECUTABLE mkfs.fat REQUIRED)
find_program(MCOPY_EXECUTABLE mcopy REQUIRED)

set(SOS_FLOPPY_IMAGE "${SOS_ARTIFACTS_DIR}/sOS.img")
set(SOS_FLOPPY_SIZE 1474560)
set(SOS_KERNEL_BIN "${SOS_ARTIFACTS_DIR}/kernel.bin")

add_custom_command(
    OUTPUT "${SOS_FLOPPY_IMAGE}"

    COMMAND "${CMAKE_COMMAND}" -E make_directory
        "${SOS_ARTIFACTS_DIR}"

    COMMAND /bin/sh -c
        "truncate -s ${SOS_FLOPPY_SIZE} '${SOS_FLOPPY_IMAGE}'"

    # 1. Crea il filesystem FAT12
    COMMAND "${MKFS_FAT_EXECUTABLE}"
        -F 12
        -n SOS
        "${SOS_FLOPPY_IMAGE}"

    # 2. Inserisce il kernel nel filesystem
    COMMAND "${MCOPY_EXECUTABLE}"
        -i "${SOS_FLOPPY_IMAGE}"
        "${SOS_KERNEL_BIN}"
        ::KERNEL.BIN

    # 3. Installa il boot sector personalizzato per ultimo
    COMMAND /bin/dd
        "if=${SOS_BOOT_SECTOR}"
        "of=${SOS_FLOPPY_IMAGE}"
        bs=512
        count=1
        conv=notrunc

    DEPENDS
        "${SOS_BOOT_SECTOR}"
        "${SOS_KERNEL_BIN}"

    COMMENT "Creating FAT12 image with boot sector and kernel"
    VERBATIM
)

add_custom_target(floppy
    DEPENDS "${SOS_FLOPPY_IMAGE}"
)

add_dependencies(floppy bootsector kernel-bin)
