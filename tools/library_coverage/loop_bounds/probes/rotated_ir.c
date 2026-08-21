/* bd 8zj2 — CORRECTION. The earlier totality sweep used SOURCE semantics
 * (test-first). clang -O1 ROTATES these loops, so the body the pass sees is
 * do-while: the shift happens BEFORE the first test. That changes which inputs
 * diverge. Re-measured in the rotated form, exhaustively, with the enclosing
 * guards SPECULATED AWAY (which is what PredMux does: br i1 5->0 / 4->0). */
#include <stdio.h>
#include <stdint.h>

/* ilogb.f64 :40/:42 and ilogbf.f32 :35, rotated:
     do { v = v<<1; n++; } while (v > 0);            [%18 = shl %16,1; %19 = icmp sgt %18,0] */
static long shl_rot(uint32_t init, unsigned cap) {
  int32_t v = (int32_t)init; unsigned n = 0;
  do { v = (int32_t)((uint32_t)v << 1); if (++n > cap) return -1; } while (v > 0);
  return (long)n;
}

/* ilogbl.f80 :41 / logbl.f80 :40, rotated:
     do { b++; m >>= 1; } while ((m & w) == 0);      [%25 = lshr %23,1; %27 = icmp eq %26,0]
   NOTE the lshr precedes the first test, so bit 31 of w is NEVER tested inside
   the loop -- it is peeled into the entry guard. */
static long mask_rot(uint64_t w, unsigned cap) {
  uint64_t m = 2147483648ull; unsigned n = 0;
  do { m >>= 1; if (++n > cap) return -1; } while ((m & w) == 0);
  return (long)n;
}

int main(void) {
  unsigned worst = 0, nonterm = 0; uint32_t first = 0;
  for (uint64_t i = 0; i <= 0xffffffffull; i++) {
    long n = shl_rot((uint32_t)i, 64);
    if (n < 0) { if (!nonterm) first = (uint32_t)i; nonterm++; }
    else if ((unsigned)n > worst) worst = (unsigned)n;
  }
  printf("shl_rot  (f64/f32 body, guards speculated): non-terminating=%u  worst trips=%u\n",
         nonterm, worst);

  unsigned worst2 = 0, nonterm2 = 0;
  printf("mask_rot (f80 body,     guards speculated): diverging inputs =");
  for (uint64_t i = 0; i <= 0xffffffffull; i++) {
    long n = mask_rot(i, 64);
    if (n < 0) { nonterm2++; if (nonterm2 <= 4) printf(" 0x%llx", (unsigned long long)i); }
    else if ((unsigned)n > worst2) worst2 = (unsigned)n;
  }
  printf("   (total %u)  worst trips among terminating=%u\n", nonterm2, worst2);
  return 0;
}
