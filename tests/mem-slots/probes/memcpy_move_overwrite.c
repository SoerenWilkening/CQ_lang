#include "CQ.h"
/* cq-n7yy (CR rules 5, 20, 22; gate 2a slots-h1 p3): a memcpy moves a's handles into b (cq-bfz4, no in-place
   write follows), then a plain store overwrites a source cell. The overwritten rail stays b's: its clean-up
   follows b's run-time read (a merge over the rails memcpy named, M3), never at the overwrite. */
int memcpy_move_overwrite(int k, int j) {
  int x = 0; cq_theta(&x, 0.5);
  int a[4], b[4];
  a[0] = x + 1; a[1] = x + 2; a[2] = x * 3; a[3] = x ^ 9;
  __builtin_memcpy(b, a, 16);
  a[1] = x * 5;
  return b[k & 3] + a[j & 3];
}
/* The moved cell holds the register x itself. */
int memcpy_move_overwrite_reg(int k, int j) {
  int x = 0; cq_theta(&x, 0.5);
  int a[4], b[4];
  a[0] = x + 1; a[1] = x; a[2] = x * 3; a[3] = 3;
  __builtin_memcpy(b, a, 16);
  a[1] = x * 5;
  return b[k & 3] + a[j & 3];
}
/* The moved cell holds a seed, overwritten by a classical store. */
int memcpy_move_overwrite_seed(int k, int j) {
  int x = 0; cq_theta(&x, 0.5);
  int a[4], b[4];
  a[0] = x + 1; a[1] = 7; a[2] = x * 3; a[3] = 3;
  __builtin_memcpy(b, a, 16);
  a[1] = 5;
  return b[k & 3] + a[j & 3];
}
