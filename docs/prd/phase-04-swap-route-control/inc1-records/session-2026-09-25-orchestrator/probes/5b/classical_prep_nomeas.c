#include <stdbool.h>
int slice(int u) {
  bool b = false;
  if (u > 0) b = cq_theta(b, 0.5);
  int a = 5;
  if (b) a = 2;
  return cq_measure(a);
}
int main(void) { return slice(4); }
