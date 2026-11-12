/* tests/loops-classical probe (CR rule 6, rule 14; cq-d4c4m): a carried rule-6 register of a classically bounded loop
 * whose update block is not its segment's last: a memset's classical loop after the update extends the segment. The
 * clean-ups of the old rail and of the chain's intermediate (acc * 3) are placed at the end of the update's block, per
 * trip. r6_mid_join: the update past a classical join; r6_mid_head: in the header's block. Each entry §6-checked.
 * Regenerate r6_mid.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec -include CQ.h r6_mid.c -o r6_mid.O1.ll */
#include <string.h>
unsigned r6_mid_join(unsigned x0, double th, int c, unsigned m, unsigned n) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned acc = 0, cell = 0;
  unsigned *volatile p = &cell;
  unsigned *f = p;
  unsigned char buf[8] = {0};
  for (unsigned i = 0; i < (m & 3); i++) {
    unsigned y = x + i;
    if (c & 1) *f ^= y;
    acc = acc * 3 + y;
    memset(buf, (unsigned char)y, n & 7);
  }
  return cq_measure(acc) * 256 + cq_measure(*f) + cq_measure(buf[1]) * 65536;
}
unsigned r6_mid_head(unsigned x0, double th, unsigned m, unsigned n) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned acc = 0;
  unsigned char buf[8] = {0};
  for (unsigned i = 0; i < (m & 3); i++) {
    unsigned y = x + i;
    acc = acc * 3 + y;
    memset(buf, (unsigned char)y, n & 7);
  }
  return cq_measure(acc) + cq_measure(buf[1]) * 65536;
}
