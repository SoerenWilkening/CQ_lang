#include <stdbool.h>
/* CONTROL for c1: byte-identical program with the b[1] read moved AFTER the
   loop. The gep is in the same place (preheader/entry); only the LOAD moved. */
int slice(void) {
  int a = 5, s = 0; bool b[3] = {0};
  for (int i = 0; i < 3; ++i) { if (a >= 3) b[i] = cq_theta(b[i], .5); }
  s += b[1];
  return s + cq_measure(a);
}
int main(void){ return slice(); }
