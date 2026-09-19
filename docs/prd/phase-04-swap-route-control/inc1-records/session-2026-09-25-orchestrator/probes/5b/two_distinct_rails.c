/* BOUNDARY: a classical-condition phi muxing TWO DISTINCT tainted registers.
   This is the genuine no-cloning data mux declineClassicalMuxes exists to
   refuse. It MUST keep declining after 5b-i. */
#include <stdbool.h>
int slice(int u) {
  int p = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.25);
  int a;
  if (u > 0) a = p; else a = r;
  return cq_measure(a);
}
int main(void) { return slice(4); }
