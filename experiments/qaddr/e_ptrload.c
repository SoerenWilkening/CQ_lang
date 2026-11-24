/* a struct {long n; long *p;} chosen by a quantum index: the pointer field is a pointer load at an address rail
 * (CR rule 20: __cq_pointer on its result), the integer field is not. */
static long A[8], B[8], C[8], D[8];
struct ent { long n; long *p; };
static struct ent T[4] = {{1, A}, {2, B}, {3, C}, {4, D}};
long f(unsigned char q0) {
    unsigned char q = q0; cq_theta(&q, 0.5);
    struct ent *e = &T[q & 3];
    return e->n + e->p[q >> 2 & 7];
}
long fw(unsigned char q0) {
    for (int i = 0; i < 8; i++) { A[i] = i; B[i] = 10 * i; C[i] = 100 + i; D[i] = 7 - i; }
    return f(q0);
}
int main(void) { return (int)cq_measure(fw(45) & 127); }
