#include <stdbool.h>
#include <string.h>
/* The bank is RE-ZEROED at the top of every trip. The carve's C1 initializer
   clause only asks DT.dominates(Init, SI) -- which an in-loop memset satisfies --
   while its own comment claims it refuses "a re-zeroing write reachable inside
   the loop".  After the deferred type rewrite cells 0..N-2 read as handle 0 = a
   LIVE RAIL, which is exactly the hazard C6 exists to prevent. */
int slice(void) {
  int a = 5; bool b[3];
  for (int i = 0; i < 3; ++i) {
    memset(b, 0, 3);
    if (a >= 3) b[i] = cq_theta(b[i], .5);
    if (b[i]) a -= 3;
  }
  int s = cq_measure(a);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s;
}
int main(void){ return slice(); }
