/* cq-025xt (bead reproducer): no cq_* call, so cq-lower is the identity and printf is the host's (CR §0, rule 16
 * Results): the reference is the host's own call and result, "0x0" on macOS, n 3, r 3 (musl's would be 1, 1). */
#include <stdio.h>
int pcp(int x) {
  int n = -1;
  int r = printf("%p%n", (void *)0, &n);
  return n * 16 + r + x;
}
