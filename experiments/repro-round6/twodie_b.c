#include <stdlib.h>
__attribute__((noreturn, noinline)) void die(int c) { exit(c & 7); }
