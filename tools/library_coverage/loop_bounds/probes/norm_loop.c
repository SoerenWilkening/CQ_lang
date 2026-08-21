/* Verify the critic's finding about the L3 memo's OWN recommended next step.
 * SCOPING-L3.md:294-296 item 1 proposes a "shift-until-normalized" recognizer for
 * e_fmod.c:112, asserting its real bound "IS a mantissa-width fact (<= 23/52/63
 * shifts, since hx|lx != 0 on entry)". Is that entry condition load-bearing? */
#include <stdio.h>
#include <stdint.h>
static long norm(uint32_t hx0, uint32_t lx0, unsigned cap) {   /* e_fmod.c:112-115 */
  int32_t hx = (int32_t)hx0, lx = (int32_t)lx0; unsigned n = 0;
  while (hx < 0x00100000) { hx = hx + hx + (int32_t)((uint32_t)lx >> 31); lx = lx + lx;
                            if (++n > cap) return -1; }
  return (long)n;
}
int main(void) {
  printf("e_fmod.c:112 normalize loop, guard `hx|lx != 0` (:110) IGNORED:\n");
  printf("  hx=1 lx=0            -> %ld\n", norm(1, 0, 4096));
  printf("  hx=0 lx=1            -> %ld\n", norm(0, 1, 4096));
  printf("  hx=0 lx=0  (GUARD-EXCLUDED) -> %ld   (-1 = did not terminate in 4096)\n",
         norm(0, 0, 4096));
  return 0;
}
