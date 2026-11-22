#include "CQ.h"
// USERCHECK f
// cq-zueka (CR rule 14 with rules 8, 9): a classically bounded loop whose trip holds two quantum arms, each ending in a
// classical switch into the same two joins (the phase and the latch); TinyEMU pci_data_write's shape. The case edges'
// fact is a disjunction of cases, which the edge predicate's classical factor dropped: the first arm's case edges alone
// were taken to cover where the other arm runs, so its default edge reached the phase without running that arm.
void f(int n, int a, int b) {
  for (int i = 0; i < n; i++) {
    bool q = 0;
    cq_theta(&q, 1.0 + i);
    if (q) {
      switch (a + i) { case 1: case 5: case 9: continue; }
    } else {
      switch ((unsigned char)(b * i)) { case 3: case 7: case 11: continue; }
    }
    cq_phi(0.5);
  }
}
