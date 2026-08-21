/* bd 8zj2 — is the f80 mask-shift loop STRUCTURALLY bounded (like the f64/f32
 * shl loop), or bounded only by an earlier GUARD on the quantum data?
 * The distinction is the whole gate question: a bound that holds for every
 * value of the input is provable from the loop alone; a bound that holds only
 * for guard-admitted values is not, and under a predicated/flattened lowering
 * every basis state runs the body -- including the ones the guard excludes. */
#include <stdio.h>
#include <stdint.h>

/* src/s_ilogbl.c:41 / src/s_logbl.c:40 verbatim, manh branch */
static long f80_manh_loop(uint64_t manh, unsigned cap) {
  unsigned long m = 1lu << (32 - 1);
  long b = 0;
  unsigned n = 0;
  while (!(manh & m)) { m >>= 1; b++; if (++n > cap) return -1; }
  return (long)n;
}

/* src/s_ilogb.c:40 shape: shift the DATA, test its sign */
static long f64_shl_loop(uint32_t lx, unsigned cap) {
  int32_t v = (int32_t)lx;
  unsigned n = 0;
  while (v > 0) { v = (int32_t)((uint32_t)v << 1); n++; if (n > cap) return -1; }
  return (long)n;
}

int main(void) {
  printf("--- f80 mask loop (and-then-eq-0), cap 1000 ---\n");
  printf("  manh=0x80000000 -> %ld\n", f80_manh_loop(0x80000000u, 1000));
  printf("  manh=0x1        -> %ld\n", f80_manh_loop(0x1u, 1000));
  printf("  manh=0   (guard-EXCLUDED basis state) -> %ld   (-1 == did NOT terminate within 1000)\n",
         f80_manh_loop(0u, 1000));

  printf("\n--- f64/f32 shl loop (shift data, test sign), cap 1000 ---\n");
  printf("  lx=0x1  -> %ld\n", f64_shl_loop(0x1u, 1000));
  printf("  lx=0    (guard-excluded) -> %ld\n", f64_shl_loop(0u, 1000));
  printf("  lx=0x7fffffff -> %ld\n", f64_shl_loop(0x7fffffffu, 1000));
  printf("  lx=0x80000000 (negative, guard-excluded) -> %ld\n", f64_shl_loop(0x80000000u, 1000));

  /* EXHAUSTIVE: does the f64/f32 shl loop terminate within 32 for EVERY 32-bit
     input, guard or no guard? */
  unsigned worst = 0; int bad = 0;
  for (uint64_t l = 0; l <= 0xffffffffull; l++) {
    long n = f64_shl_loop((uint32_t)l, 64);
    if (n < 0) { bad = 1; break; }
    if ((unsigned)n > worst) worst = (unsigned)n;
  }
  printf("\nEXHAUSTIVE over ALL 2^32 inputs, shl loop: terminates always=%s, worst trips=%u\n",
         bad ? "NO" : "YES", worst);

  /* EXHAUSTIVE: same question for the f80 mask loop. */
  unsigned worst2 = 0; unsigned nonterm = 0;
  for (uint64_t h = 0; h <= 0xffffffffull; h++) {
    long n = f80_manh_loop(h, 64);
    if (n < 0) { nonterm++; if (nonterm == 1) printf("  first non-terminating manh = 0x%llx\n", (unsigned long long)h); }
    else if ((unsigned)n > worst2) worst2 = (unsigned)n;
  }
  printf("EXHAUSTIVE over ALL 2^32 inputs, mask loop: non-terminating inputs=%u, worst trips among terminating=%u\n",
         nonterm, worst2);
  return 0;
}
