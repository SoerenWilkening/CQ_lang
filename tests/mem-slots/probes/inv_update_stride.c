#include "CQ.h"
/* cq-ja4w (CR §1.4 _inv<c>, rules 6, 18; gate 2a review calls-h2 b7): the clone overwrites cell 1 of a short
   array. The slot object holds one i32 handle per cell, so the _inv clone reads the new content at i32 cell
   index 1 (byte 4), as the forward clone does; main addressed it at byte 2 (cell * sizeof(short)) and read a
   garbage handle, then freed the old rail dirty. */
static __attribute__((noinline)) void inc3(short *p) { p[1] = p[1] * 5; }
int inv_update_stride(int a0, int b0, double th) {
  short c[2] = {a0, b0};
  cq_theta(&c[1], th);
  inc3(c);
  return cq_measure(c[1]);
}
