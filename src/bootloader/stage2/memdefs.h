#pragma once

// WARN: 0x00000000 - 0x000003FF - interrupt vector table
// WARN: 0x00000400 - 0x000004FF - BIOS data area

#define MEMORY_MIN 0x00000500
#define MEMORY_MAX 0x00080000

// INFO: 0x00000500 - 0x00010500 - FAT driver
#define MEMORY_FAT_ADDR                                                        \
  ((void far *)0x00500000) // INFO: segment:offset (SSSSOOOO)
#define MEMORY_FAT_SIZE 0x00010000

// INFO: 0x00020000 - 0x00030000 - stage2

// INFO: 0x00030000 - 0x00080000 - free

// WARN: 0x00080000 - 0x0009FFFF - Extended BIOS data area
// WARN: 0x000A0000 - 0x000C7FFF - Video
// WARN: 0x000C8000 - 0x000FFFFF - BIOS
