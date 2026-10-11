#include "stdint.h"
#include "stdio.h"

void _cdecl cstart_(uint16_t bootDrive) {
  printf("Hello world from C!\n");
  printf("5 + 5 = %d", 5 + 5);
  for (;;)
    ;
}
