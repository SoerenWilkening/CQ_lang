/* PART B — the null path of `loopExitDischargePoint`: a loop with TWO DISTINCT
   exit blocks (two `return`s reached from inside), each with a different value
   so -O1 cannot merge them, and a hoisted rail read in the body.  Expected:
   getUniqueExitBlock() == null => anchorForConsumer returns nullptr =>
   planInteriorComponent returns false => the rail LEAKS (Rule 6's fallback).
   The property to check is that NO PARTIAL discharge escapes. */
volatile int g = 1;
int slice(int lim) {
    int a = 0;
    a = cq_theta(a, 0.5);
    int p = a * 3;
    int s = 0;
    for (int i = 0; i < 4; ++i) {
        s += cq_measure((p >> i) & 1);
        if (s > lim)  { g = 7; return s + 100 + cq_measure(a); }
        if (i > lim)  { g = 9; return s + 200 + cq_measure(a); }
    }
    return s + cq_measure(a);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }
