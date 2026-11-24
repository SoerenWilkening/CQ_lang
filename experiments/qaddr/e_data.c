/* one object holding integers and a pointer: a computed store at an address rail is announced as data (CR rule 20:
 * __cq_data before it), a copy between its cells is not; the pointer field keeps its note for the load through it. */
static long A[8];
struct obj { long count[4]; long *p; };
static struct obj s;
__attribute__((noinline)) long g(unsigned char q) {
    s.count[q & 3] += 1;                       /* computed: __cq_data */
    s.count[q & 3] = s.count[(q >> 2) & 3];    /* a copy: nothing */
    return s.p[q & 7] + s.count[q & 3];
}
long f(unsigned char q0) {
    unsigned char q = q0; cq_theta(&q, 0.5);
    return g(q);
}
long fw(unsigned char q0) {
    for (int i = 0; i < 8; i++) A[i] = 3 * i + 1;
    for (int i = 0; i < 4; i++) s.count[i] = i;
    s.p = A;
    return f(q0);
}
int main(void) { return (int)cq_measure(fw(45) & 127); }
