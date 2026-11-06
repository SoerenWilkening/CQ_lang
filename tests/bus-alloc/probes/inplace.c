/* tests/bus-alloc: CR rule 5 In-place form, the shapes that are not the form or are the form at the store's position.
   Regenerate inplace.O1.ll: clang -O1 -S -emit-llvm -include CQ.h inplace.c -o inplace.O1.ll (LLVM 19.1.7, corpus triple). */
int g[8];
__attribute__((noinline)) void put(int *p, int v) { *p = v; }
#define I1                                                                                                             \
    int x = cq_theta_si32(x0, t);                                                                                      \
    put(&g[0], x);                                                                                                     \
    put(&g[1], x + 1);                                                                                                 \
    put(&g[2], x ^ 5);

/* cq-q148y: a step's reader before the store, a bus load between the step and the store reads the old cell */
int ip_read_add(int x0, int i, int j, double t) {
    I1 int y = g[i & 1];
    int y1 = y + x;
    int w = y1 * 3;
    int r = g[j & 1];
    g[i & 1] = y1;
    return cq_measure_si32(w ^ r);
}
int ip_read_theta(int x0, int i, int j, double t, double u) {
    I1 int y = g[i & 1];
    int y1 = cq_theta_si32(y, u);
    int w = y1 * 3;
    int r = g[j & 1];
    g[i & 1] = y1;
    return cq_measure_si32(w ^ r);
}
/* the same reader with no bus access in the interval: the part stays the form, at the step */
int ip_read_theta_nobus(int x0, int i, double t, double u) {
    I1 int y = g[i & 1];
    int y1 = cq_theta_si32(y, u);
    int w = y1 * 3;
    g[i & 1] = y1;
    return cq_measure_si32(w ^ g[1]);
}

/* cq-i2gdy: a step computed before the preceding store */
int ip_before_prev(int x0, int j, double t) {
    I1 int a = x + 7;
    put(&g[3], a);
    g[0] = x;
    int r = g[j & 1];
    g[0] = a;
    return cq_measure_si32(g[0] + r * 3);
}
void st(int *restrict p, int *restrict q, int v, int w) {
    *p = v;
    *q = w;
    *p = v + 1;
}
int ip_before_prev_change(int x0, double t) {
    I1 st(&g[0], &g[1], x, x + 5);
    return cq_measure_si32(g[0] + g[1] * 3);
}
/* Readers: a change in the interval, a step with a reader before the store */
int ip_change_reader(int x0, int *q, double t) {
    I1 g[0] = x;
    q[0] = 9;
    int y1 = x + 7;
    int w = y1 * 3;
    q[1] = w;
    g[0] = y1;
    return cq_measure_si32(g[0] + w);
}
/* the same with one change at a classical address: the run-time test d, the form on d = 1 and the copy on d = 0 */
int ip_change_reader_d(int x0, int *q, double t) {
    I1 g[0] = x;
    q[0] = 9;
    int y1 = x + 7;
    int w = y1 * 3;
    g[0] = y1;
    return cq_measure_si32(g[0] + w);
}
/* Readers: the preceding store is itself a form and the next form's step has another reader */
int ip_prev_form_reader(int x0, int j, double t) {
    I1 int y = g[0] + x;
    g[0] = y;
    int y1 = y + 5;
    int w = y1 * 3;
    int r = g[j & 1];
    g[0] = y1;
    return cq_measure_si32(w ^ r ^ g[0]);
}

/* cq-5cie9: the load before a loop, the store inside */
int ip_loop_k(int x0, int *q, double t) {
    I1 int y = g[0];
    for (int i = 0; i < (x & 3); i++) {
        g[0] = y + 1;
        q[0] = i;
    }
    return cq_measure_si32(g[0]);
}
int ip_loop_classical(int x0, int n, int *q, double t) {
    I1 int y = g[0];
    for (int i = 0; i < (n & 3); i++) {
        g[0] = y + 1;
        q[i] = i;
    }
    return cq_measure_si32(g[0]);
}
int ip_loop_classical_i(int x0, int n, int *q, double t) {
    I1 int y = g[0];
    for (int i = 0; i < (n & 3); i++) {
        g[0] = y + i;
        q[i] = i;
    }
    return cq_measure_si32(g[0]);
}
/* cq-6cup9: a narrow store forwarded to a wider zext store: the high cells get the 0 C writes */
int ip_narrow_prev(int x0, double t) {
    I1 * (int *)&g[0] = x;
    int r = g[1];
    *(long *)&g[0] = (unsigned)(x + 5);
    return cq_measure_si32(g[0] + g[1] * 3 + r * 5);
}
/* a wide zext store forwarded: the form stands at the narrow width, the high cells hold 0 */
int ip_wide_prev(int x0, double t) {
    I1 * (long *)&g[0] = (unsigned)x;
    int r = g[2];
    *(long *)&g[0] = (unsigned)(x + 5);
    return cq_measure_si32(g[0] + g[1] * 3 + r * 5);
}
/* the same with a change to the high cells in the interval: the store writes them 0 again */
int ip_wide_prev_change(int x0, int *q, double t) {
    I1 * (long *)&g[0] = (unsigned)x;
    g[1] = 77;
    q[0] = 3;
    *(long *)&g[0] = (unsigned)(x + 5);
    return cq_measure_si32(g[0] + g[1] * 3);
}
int ip_wide_prev_change_q(int x0, int *q, double t) {
    I1 * (long *)&g[0] = (unsigned)x;
    q[0] = 77;
    *(long *)&g[0] = (unsigned)(x + 5);
    return cq_measure_si32(g[0] + g[1] * 3);
}
