#include <stdarg.h>
#include <stdint.h>

extern int printf(const char *format, ...);

char getchar(void) {
  uint32_t size_left = *((volatile uint32_t *)0x80000008);
  if (size_left == 16)
    return '\0';
  else
    return *((volatile char *)0x8000000c);
}

int main() {
  printf("START\r\n");

  // char c = getchar();
  // printf("%c", c);
  // c = getchar();
  // printf("%c", c);
  // c = getchar();
  // printf("%c", c);
  // c = getchar();
  // printf("%c", c);
  // c = getchar();
  // printf("%c", c);
  // c = getchar();
  // printf("%c", c);
  for (int i = 0; i < 6; i++) {
    char c = getchar();
    printf("%c", c);
  }

  printf("DONE\r\n");
  return 0;
}
