/* cq-03rdt (SQLite btreeOverwriteContent, sqlite3GetCollSeq): the index a loop with a quantum exit leaves with addresses
   a memcpy. Rule 22 uncomputes the copy's address rail and what produced it between its two loops (bus resolveFinished);
   the loop's exit rail, a select over the trips, is the loop's deferred item's and goes with it: resolveAt refused it. */
#include <string.h>
char buf[8];
char dst[12];
int memleak(long b, int n) {
  memcpy(buf, &b, 8);
  cq_theta(&buf[1], 0.5);
  int i;
  for (i = 0; i < (n & 7); i++)
    if (buf[i] != 0)
      break;
  memset(dst, 1, i & 7);
  return cq_measure(dst[1] + dst[2]);
}
