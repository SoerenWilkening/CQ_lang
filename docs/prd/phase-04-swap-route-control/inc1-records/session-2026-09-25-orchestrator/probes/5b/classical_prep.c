#include <stdbool.h>
int slice(int u) {
  bool b = false;
  if (u > 0) b = cq_theta(b, 0.5);   /* CLASSICAL condition */
  int a = 5;
  if (b) a = 2;                       /* quantum control on the rail phi */
  return cq_measure(a) + (int)cq_measure(b);
}
int main(void) { return slice(4); }
