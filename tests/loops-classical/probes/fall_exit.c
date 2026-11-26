/* tests/loops-classical probe (cq-6ce8r; CR rules 9, 14 case 3): a classical bound whose latch test lies behind a switch
 * case that tests and falls through into the next, which tests and exits. The latch is reached only past quantum exits,
 * and a path that leaves the loop skips no later trip's test: the loop runs the n trips C runs, never a K cutoff.
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec fall_exit.c -o fall_exit.O1.ll */
#include "CQ.h"
#include <stdint.h>
struct Op { int opcode, p1, p2; };
int fe_fall(uint8_t n) {
  uint8_t q = 0; cq_theta(&q, 0.5);
  struct Op ops[8];
  int reg[4] = {1, 0, 2, 0}, rc = 0;
  for (int i = 0; i < 8; i++) { ops[i].opcode = (q >> i) & 1; ops[i].p1 = i & 3; ops[i].p2 = (i + 1) & 3; }
  for (int t = 0; t < n % 9; t++) {
    switch (ops[t].opcode) {
    case 0: reg[ops[t].p2] += 3; if (reg[ops[t].p1] > 0) break;
    case 1: reg[ops[t].p2] += 4; if (reg[ops[t].p1] > 1) break;
    default: rc = -1; goto done;
    }
  }
done:
  return cq_measure(rc + reg[0] + 64 * reg[1] + 4096 * reg[2]);
}
