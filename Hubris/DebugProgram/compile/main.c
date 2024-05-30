#include <stdarg.h>

extern int printf(const char *format, ...);

char test_string[] = "this is a test string, it will be printed continuously";

int main() {
  printf("START\n");

  for (int i = 0; i < 10; i++)
    printf("%s\n", test_string);

  printf("DONE\n");
  return 0;
}
