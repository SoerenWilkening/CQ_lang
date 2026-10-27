/* Classical code only: loops, irreducible control flow, switch, recursion, fp widths, aggregates,
 * varargs, function pointers, globals, inline asm. CQ.h is included but nothing from it is used. */
#include <stdarg.h>
#include <string.h>

struct pt { int x; double y; long double z; };
int table[16] = {3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3};
static int (*hook)(int) = 0;

int irreducible(int n, int k) {
  int acc = 0;
  if (k & 1) goto inside;
  while (n > 0) {
    acc += n;
  inside:
    acc ^= k;
    n -= 2;
  }
  return acc;
}

int classify(int v) {
  switch (v) {
  case 0: return 10;
  case 3: return table[v];
  case 7: return -1;
  default: return v * 3;
  }
}

unsigned fib(unsigned n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }

long double mix(struct pt p, float f) { return p.x * p.y + p.z / (long double)f; }

int sum(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int s = 0;
  for (int i = 0; i < n; i++) s += va_arg(ap, int);
  va_end(ap);
  return s;
}

int use_hook(int v) { return hook ? hook(v) : classify(v); }

int with_asm(int v) {
  int r;
  __asm__("movl %1, %0" : "=r"(r) : "r"(v));
  return r;
}

void copy_pts(struct pt *dst, const struct pt *src, int n) { memcpy(dst, src, sizeof *dst * (unsigned)n); }
