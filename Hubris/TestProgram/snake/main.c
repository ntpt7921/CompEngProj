#include <stdarg.h>
#include <stdint.h>

#define ANSI_ESC "\x1b"
extern int printf(const char *format, ...);
inline void clear_screen(void) { printf(ANSI_ESC "[2J"); }
inline void clear_line(void) { printf(ANSI_ESC "[2K"); }
inline void move_cursor_absolute(int line, int col) {
  printf(ANSI_ESC "[%d;%dH", line, col);
}
inline void move_cursor_up_relative(int line) { printf(ANSI_ESC "[%dA", line); }
inline void move_cursor_down_relative(int line) {
  printf(ANSI_ESC "[%dB", line);
}
inline void move_cursor_right_relative(int col) {
  printf(ANSI_ESC "[%dC", col);
}
inline void move_cursor_left_relative(int col) { printf(ANSI_ESC "[%dD", col); }

void delay(int value) {
  for (int i = 0; i < value; i++)
    __asm__("nop");
}

// Linear congruential generator
// see: https://en.wikipedia.org/wiki/Linear_congruential_generator
uint32_t rand(void) {
  static uint32_t state = 79;         // just chosen randomly
  state = 1103515245 * state + 12345; // see wikipedia article above
  return state;
}

#define C 15
#define A 10
#define DELAY_VALUE 1000000

typedef struct point {
  int x;
  int y;
} point;

struct snake {
  point head;
  point tail[C * A];
  point dir;
  int isDead;
  int size;
} snk;

void init(void);
void update(void);
int checkDead(void);
void n_food(void);
void draw(void);
char getchar(void);

point food;
char in;

int main(void) {
  init();
  while (!snk.isDead) {
    delay(DELAY_VALUE);
    in = getchar();
    if (in == 'w' || in == 'W') {
      if (snk.dir.y == 0) {
        snk.dir.x = 0;
        snk.dir.y = -1;
      }
    } else if (in == 'a' || in == 'A') {
      if (snk.dir.x == 0) {
        snk.dir.x = -1;
        snk.dir.y = 0;
      }
    } else if (in == 's' || in == 'S') {
      if (snk.dir.y == 0) {
        snk.dir.x = 0;
        snk.dir.y = 1;
      }
    } else if (in == 'd' || in == 'D') {
      if (snk.dir.x == 0) {
        snk.dir.x = 1;
        snk.dir.y = 0;
      }
    }

    update();
    if (snk.head.x == food.x && snk.head.y == food.y) {
      snk.size++;
      n_food();
    }
    draw();
    snk.isDead = checkDead();
    if (snk.isDead || in == 'q' || in == 'Q')
      break;
  }

  return 0;
}

void init(void) {
  snk.size = 0;
  snk.dir.x = 1;
  snk.dir.y = 0;
  snk.head.x = C / 2;
  snk.head.y = A / 2;
  snk.isDead = 0;
  n_food();
}

void update(void) {
  int i;
  if (snk.size != 0) {
    for (i = snk.size - 1; i >= 0; i--) {
      snk.tail[i] = snk.tail[i - 1];
    }
    snk.tail[0] = snk.head;
  }
  snk.head.x += snk.dir.x;
  snk.head.y += snk.dir.y;
  if (snk.head.x == C + 1)
    snk.head.x = 0;
  else if (snk.head.x == -1)
    snk.head.x = C;
  if (snk.head.y == A + 1)
    snk.head.y = 0;
  else if (snk.head.y == -1)
    snk.head.y = A;
}

int checkDead(void) {
  int i;
  for (i = 0; i < snk.size; i++) {
    if (snk.head.x == snk.tail[i].x && snk.head.y == snk.tail[i].y)
      return 1;
  }
  return 0;
}

void n_food(void) {
  int i;
  food.x = rand() % (C - 2) + 1;
  food.y = rand() % (A - 2) + 1;
  while (snk.head.x == food.x && snk.head.y == food.y) {
    food.x = rand() % (C - 2) + 1;
    food.y = rand() % (A - 2) + 1;
  }
  for (i = 0; i < snk.size; i++) {
    while (food.x == snk.tail[i].x && food.y == snk.tail[i].y) {
      food.x = rand() % (C - 2) + 1;
      food.y = rand() % (A - 2) + 1;
    }
  }
}

void draw(void) {
  int i, j, k, flag = 0;

  clear_screen();
  move_cursor_absolute(0, 0);

  printf("  Points: %d \t", snk.size);
  for (i = 0; i < 2 * C - 14; i++) {
    printf("-");
  }
  printf("\r\n");
  for (i = 0; i <= A; i++) {
    printf("|");
    for (j = 0; j <= C; j++) {
      if (snk.head.x == j && snk.head.y == i) {
        printf("0 ");
        flag = 1;
      }
      if (food.x == j && food.y == i && flag == 0) {
        printf("* ");
        flag = 1;
      }
      for (k = 0; k < snk.size; k++) {
        if (snk.tail[k].x == j && snk.tail[k].y == i && flag == 0) {
          printf("o ");
          flag = 1;
        }
      }
      if (flag == 0) {
        printf("  ");
      }
      flag = 0;
    }
    printf("|\r\n");
  }
  printf("  ");
  for (i = 0; i < 2 * C; i++) {
    printf("-");
  }
  printf("\r\n");
}

char getchar(void) {
  int size_left = *((volatile uint32_t *)0x80000008);
  if (size_left == 16)
    return '\0';
  else
    return *((volatile char *)0x8000000c);
}
