#include <stdarg.h>

extern int printf(const char *format, ...);

int fibonacci(int n) {
  int t0 = 0;
  int t1 = 1;

  if (n == 0)
    return 0;
  else if (n == 1)
    return 1;
  else {
    for (int i = 1; i < n; ++i) {
      int temp = t0 + t1;
      t0 = t1;
      t1 = temp;
    }
    return t1;
  }
}

int main() {
  for (int i = 0; i < 10; ++i)
    printf("%d Fibonacci number is %d\n", i, fibonacci(i));
  return 0;
}
