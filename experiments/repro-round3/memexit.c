/* cq-03rdt (SQLite btreeOverwriteContent, sqlite3GetCollSeq): a loop's quantum exit leads to a memset whose address and
   length the exit index makes. Rule 22 uncomputes the length and address rails and what produced them between the two
   loops (bus resolveFinished); its walk went on into the loop's exit rail, a select over the trips that is the loop's
   deferred item's (undone by its reverse), and resolveAt refused it. */
#include <string.h>
char buf[8];
int memexit(long b, int n) {
  memcpy(buf, &b, 8);
  cq_theta(&buf[1], 0.5);
  int m = n & 7;
  for (int i = 0; i < m; i++)
    if (buf[i] != 0) {
      memset(buf + i, 0, m - i);
      return cq_measure(buf[1] + buf[2]);
    }
  return 0;
}
