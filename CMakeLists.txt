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
