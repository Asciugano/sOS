find_program(NASM_EXECUTABLE nasm REQUIRED)

set(BOOT_STAGE1_SOURCE
    "${CMAKE_CURRENT_SOURCE_DIR}/stage1/boot.asm"
)

set(BOOT_STAGE1_BINARY
    "${SOS_ARTIFACTS_DIR}/boot.bin"
)

add_custom_command(
    OUTPUT "${BOOT_STAGE1_BINARY}"

    COMMAND
        "${CMAKE_COMMAND}" -E make_directory
        "${SOS_ARTIFACTS_DIR}"

    COMMAND
        "${NASM_EXECUTABLE}"
        -f bin
        "${BOOT_STAGE1_SOURCE}"
        -o "${BOOT_STAGE1_BINARY}"

    DEPENDS "${BOOT_STAGE1_SOURCE}"

    COMMENT "Building BIOS boot sector"

    VERBATIM
)

add_custom_target(bootsector ALL
    DEPENDS "${BOOT_STAGE1_BINARY}"
)
