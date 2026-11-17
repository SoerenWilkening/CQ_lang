__attribute__((noinline)) static int dispatch(int v, int a, int b) {
    switch (v & 3) {                       /* a switch on the quantum argument, inside the callee */
    case 0:  return v + a;
    case 1:  return v * b;
    case 2:  return v - a;
    default: return v;
    }
}
__attribute__((noinline)) static int pick(int v, int c) {
    return c ? v + 1 : v * 2;              /* a classical condition choosing between two quantum arms */
}
int callee_switch(int x0, double th, int a, int b) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(dispatch(x, a, b));
}
int callee_classical_select(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(pick(x, c));
}
