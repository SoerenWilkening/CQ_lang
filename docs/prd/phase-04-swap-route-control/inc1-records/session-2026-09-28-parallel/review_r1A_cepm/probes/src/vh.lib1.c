/* h READS a (a call to g, an external here) and returns the CLASSICAL k + 1. */
void g(int a);
int h(int a, int k) { g(a); return k + 1; }
