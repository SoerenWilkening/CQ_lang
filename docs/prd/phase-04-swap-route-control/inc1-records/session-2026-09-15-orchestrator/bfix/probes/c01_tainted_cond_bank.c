#include <stdbool.h>
int slice(int seed) {
  bool b0[3]; int s = 0;
  bool q = cq_theta(seed, 0.5);          /* the condition rail */
  for (int i = 0; i < 3; ++i) {
    bool t = 0;
    if (q) t = cq_theta(t, 0.25);        /* TAINTED condition, in-loop prep */
    b0[i] = t;
  }
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
