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

void swap(int *a, int *b) {
  int temp = *a;
  *a = *b;
  *b = temp;
}

void sort(int arr[], int size) {
  // do insertion sort on array

  for (int i = 0; i < size - 1; i++) {
    int min_index = i;
    for (int j = i; j < size; j++) {
      if (arr[j] < arr[min_index])
        min_index = j;
    }
    swap(arr + i, arr + min_index);
  }
}

extern int fib_res[10];
extern int sort_res[10];

int fib_res[10] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
int sort_res[10] = {1, 4, 2, 9, 8, 5, 7, 3, 0, 6};

int main() {

  printf("fib_res before: ");
  for (int i = 0; i < 10; i++)
    printf("%d ", fib_res[i]);
  printf("\n");

  for (int i = 0; i < 10; i++)
    fib_res[i] = fibonacci(i);

  printf("fib_res after: ");
  for (int i = 0; i < 10; i++)
    printf("%d ", fib_res[i]);
  printf("\n");

  printf("sort_res before: ");
  for (int i = 0; i < 10; i++)
    printf("%d ", sort_res[i]);
  printf("\n");

  sort(sort_res, sizeof(sort_res) / sizeof(int));

  printf("sort_res after: ");
  for (int i = 0; i < 10; i++)
    printf("%d ", sort_res[i]);
  printf("\n");

  return 0;
}
