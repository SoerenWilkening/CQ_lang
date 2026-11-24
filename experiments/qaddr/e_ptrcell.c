/* a pointer stored through a quantum-chosen address, loaded back and indexed: the loaded pointer must keep its object. */
static long A[64], B[64];
static long *slot[2];
int main(void) {
    for (int i = 0; i < 64; i++) { A[i] = i + 1; B[i] = 100 - i; }
    unsigned char q = 5; cq_theta(&q, 0.0);
    slot[0] = B; slot[1] = B;
    slot[q & 1] = A;                         /* a store at a quantum address marks the cells quantum */
    long *p = slot[1];                       /* classical address, quantum cell */
    return (int)cq_measure(p[q >> 1 & 3] & 127);
}
