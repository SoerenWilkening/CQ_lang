__attribute__((noinline)) static int readout(int v, int k) {
    int m = cq_measure(v);                 /* the callee measures its quantum argument */
    return m > k ? m : k;
}
int callee_measure(int x0, double th, int k, int c) {
    int x = x0;
    cq_theta(&x, th);
    int y = x + c;                         /* entangled with x: collapses with it */
    int m = readout(x, k);
    return m + cq_measure(y);
}
