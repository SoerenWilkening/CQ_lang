#include <stdbool.h>
/* The array's C scope is the loop body, so clang emits ONE static alloca with
   llvm.lifetime.start/end INSIDE the loop. The carve's alloca-wide user scan
   `continue`s on a lifetime marker with NO location check at all. */
int slice(void) {
  int a = 5;
  for (int i = 0; i < 3; ++i) {
    bool b[3] = {0};
    if (a >= 3) b[i] = cq_theta(b[i], .5);
    if (b[i]) a -= 3;
  }
  return cq_measure(a);
}
int main(void){ return slice(); }
