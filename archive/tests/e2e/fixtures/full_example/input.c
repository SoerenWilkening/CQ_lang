#include <CQ.h>

int main(void) {
    quantum int x;                  // pattern 1
    quantum int y = 5;              // pattern 2 (literal)
    int classic = 7;
    quantum int z = classic;        // pattern 2 (classical var)
    quantum int a = 3, b = 2;       // multi-decl, both pattern 2
    quantum int c = a + b;          // pattern 3 (Q + Q)
    quantum int d = a + 5;          // pattern 4 (Q + classical literal)
    quantum int e = a + classic;    // pattern 4 (Q + classical var)
    int mc = (int) c;               // measure c (keeps Q+Q add live)
    int md = (int) d;               // measure d (keeps Q+C literal add live)
    int me = (int) e;               // measure e (keeps Q+C classical-var add live)
    (void) x;
    (void) y;
    (void) z;
    (void) mc;
    (void) md;
    (void) me;
    return 0;
}
