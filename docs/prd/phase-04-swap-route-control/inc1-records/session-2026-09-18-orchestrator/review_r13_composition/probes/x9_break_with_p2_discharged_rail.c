// COMPOSITION ATTACK 5. The loopconv round said break loops are protected only
// because the mint and the discharge share a block; P2 puts the discharge in the
// EXIT block by design. Here a hoisted rail is P2-discharged and a classical
// `break` is taken. -O1 folds a latch break into one extra disjunct on the LATCH
// (IMPL note at `anchorForConsumer`), so the loop stays single-exit; the question
// is whether the rail is discharged on the BREAK path too, exactly once.
#include <CQ.h>
int main(void) {
  volatile int lim_v = 2;
  int lim = lim_v;
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 4; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
    if (i == lim) break;
  }
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r);
}
