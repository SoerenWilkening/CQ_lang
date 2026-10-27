__attribute__((noinline)) static int pick(int v, int k, int a, int b) {
    return v > k ? v + a : v * b;         /* a quantum int with conditional values, returned to the caller */
}
int call_result_as_target(int x0, double th, int k, int a, int b, double t) {
    int x = x0;
    cq_theta(&x, th);
    int y = pick(x, k, a, b);
    cq_theta(&y, t);                      /* the call result is the register a second rotation acts on */
    return cq_measure(y) + cq_measure(x);
}
__attribute__((noinline)) static unsigned char pick8(unsigned char v, unsigned char k) {
    return v > k ? v + 1 : v * 2;        /* 8-bit twin of pick: keeps the bit ladder below to 8 rungs */
}
int call_result_as_theta_angle(unsigned char x0, double th, unsigned char k, int r0, double s) {
    unsigned char x = x0;
    cq_theta(&x, th);
    int r = r0;
    cq_theta(&r, s * pick8(x, k));        /* the call result is the ANGLE: a quantum-valued rotation angle */
    return cq_measure(r) + cq_measure(x);
}
int call_result_as_phi_angle(unsigned char x0, double th, unsigned char k, double s) {
    unsigned char x = x0;
    cq_theta(&x, th);
    cq_phi(s * pick8(x, k));              /* the call result is a branch PHASE: e^(i s v) on each branch */
    return cq_measure(x);
}
