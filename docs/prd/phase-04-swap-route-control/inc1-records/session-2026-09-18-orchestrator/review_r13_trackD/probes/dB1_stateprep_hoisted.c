// ATTACK 4: controlled STATE PREP under a hoisted loop-invariant compare.
// P4 ran BEFORE F1/F2 (ArmClassify.cpp: condWireDisposition :4607 < F1 :5146 < F2 :5263),
// so a cross-block compare now reaches the state-prep fences for the FIRST time.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int acc = 0;
  for (int i = 0; i < 2; i++) {
    int r = 3;
    if (q == 5) r = cq_theta(3, 0.4);
    acc += cq_measure(r);
  }
  return acc + cq_measure(q);
}
