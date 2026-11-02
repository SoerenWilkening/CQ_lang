#include "CQ.h"
/* cq-qrvh (CR rules 9, 20; 90): a classical store wider than its byte cells under a quantum predicate: each byte cell
   receives select(predicate, its byte, old). */
#include <string.h>
int split_guarded(int x0, double th, int k, int j) {
  int x = x0; cq_theta(&x, th);
  unsigned char b[4];
  int v = 0x01020304 ^ k;
  memcpy(b, &v, 4);
  b[1] = (unsigned char)x;
  if (x > 3) { int w = 0x0a0b0c0d + k; memcpy(b, &w, 4); }
  return cq_measure(b[j & 3] + 3 * b[1]);
}
