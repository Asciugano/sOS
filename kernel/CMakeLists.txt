file(GLOB_RECURSE KERNEL_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/*.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/*.S"
    "${CMAKE_CURRENT_SOURCE_DIR}/*.s"
    "${CMAKE_CURRENT_SOURCE_DIR}/*.asm"
)

set(KERNEL_LINKER_SCRIPT
    "${CMAKE_CURRENT_SOURCE_DIR}/linker.ld"
)

add_executable(kernel.elf ${KERNEL_SOURCES})

set_target_properties(kernel.elf PROPERTIES
    OUTPUT_NAME "kernel.elf"
    SUFFIX ""
    LINKER_LANGUAGE C
    LINK_DEPENDS "${KERNEL_LINKER_SCRIPT}"
)

target_compile_options(kernel.elf PRIVATE
    $<$<COMPILE_LANGUAGE:C>:-ffreestanding>
    $<$<COMPILE_LANGUAGE:C>:-fno-stack-protector>
    $<$<COMPILE_LANGUAGE:C>:-fno-pic>
    $<$<COMPILE_LANGUAGE:C>:-fno-pie>
    $<$<COMPILE_LANGUAGE:C>:-mno-red-zone>
    $<$<COMPILE_LANGUAGE:C>:-mcmodel=kernel>
    $<$<COMPILE_LANGUAGE:C>:-Wall>
    $<$<COMPILE_LANGUAGE:C>:-Wextra>
)

target_link_options(kernel.elf PRIVATE
    -nostdlib
    -static
    -no-pie
    "-Wl,-T,${KERNEL_LINKER_SCRIPT}"
    -Wl,--build-id=none
    -Wl,-z,max-page-size=0x1000
)
