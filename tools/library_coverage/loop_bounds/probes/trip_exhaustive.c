/* bd 8zj2 — is SCEV's constant max BTC of 32 actually an UPPER BOUND on the real
 * trip count of the ilogb subnormal loops? Exhaustive over every reachable input
 * to each loop (the loops read a masked 32-bit word, so the domain is finite and
 * small enough to enumerate completely — no sampling). */
#include <stdio.h>
#include <stdint.h>

int main(void) {
  /* s_ilogbf.c:35   for (ix=-126, hx<<=8; hx>0; hx<<=1) ix-=1;
     reachable hx: (bits & 0x7fffffff) < 0x00800000, and hx != 0. */
  uint32_t worst_f32 = 0, arg_f32 = 0;
  for (uint32_t hx0 = 1; hx0 < 0x00800000u; hx0++) {
    int32_t hx = (int32_t)(hx0 << 8);
    uint32_t n = 0;
    while (hx > 0) { hx = (int32_t)((uint32_t)hx << 1); n++; }
    if (n > worst_f32) { worst_f32 = n; arg_f32 = hx0; }
  }
  printf("ilogbf.f32  s_ilogbf.c:35   max BACKEDGE-taken = %u  (trips = %u)  at hx=0x%x\n",
         worst_f32 ? worst_f32 - 1 : 0, worst_f32, arg_f32);

  /* s_ilogb.c:42    for (ix=-1022, hx<<=11; hx>0; hx<<=1) ix-=1;
     reachable hx: 0 < hx < 0x00100000. */
  uint32_t worst_hi = 0, arg_hi = 0;
  for (uint32_t hx0 = 1; hx0 < 0x00100000u; hx0++) {
    int32_t hx = (int32_t)(hx0 << 11);
    uint32_t n = 0;
    while (hx > 0) { hx = (int32_t)((uint32_t)hx << 1); n++; }
    if (n > worst_hi) { worst_hi = n; arg_hi = hx0; }
  }
  printf("ilogb.f64   s_ilogb.c:42    max BACKEDGE-taken = %u  (trips = %u)  at hx=0x%x\n",
         worst_hi ? worst_hi - 1 : 0, worst_hi, arg_hi);

  /* s_ilogb.c:40    for (ix=-1043; lx>0; lx<<=1) ix-=1;
     reachable lx: the FULL low word, any value with lx > 0 on entry
     (the loop is guarded by `lx > 0` in the -O1 IR). Enumerate all 2^31. */
  uint32_t worst_lo = 0, arg_lo = 0;
  for (uint32_t l = 1; l < 0x80000000u; l++) {
    int32_t lx = (int32_t)l;
    uint32_t n = 0;
    while (lx > 0) { lx = (int32_t)((uint32_t)lx << 1); n++; }
    if (n > worst_lo) { worst_lo = n; arg_lo = l; }
  }
  printf("ilogb.f64   s_ilogb.c:40    max BACKEDGE-taken = %u  (trips = %u)  at lx=0x%x\n",
         worst_lo ? worst_lo - 1 : 0, worst_lo, arg_lo);
  printf("\nSCEV reports constant max BACKEDGE-taken = 32, getSmallConstantMaxTripCount = 33.\n");
  return 0;
}
