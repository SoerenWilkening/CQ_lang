/* Rules 21, 20, 26: a struct whose pointer field depends on quantum data. n.p is a pointer that depends on quantum data:
 * one 64-bit address rail select(x > k, &bufA, &bufB). &n.p[n.w] is address arithmetic on that rail, and *(&n.p[n.w])
 * is ONE bus load at it (rule 21). bufA and bufB are bus-resident (rule 20 (b)). */
struct node { int *p; int w; };
int struct_quantum_ptr_field(int x0, double tx, int k, int a, int b) {
    int bufA[4] = { a, a + 1, a + 2, a + 3 };
    int bufB[4] = { b, b + 1, b + 2, b + 3 };
    int x = x0;
    cq_theta(&x, tx);
    struct node n = { (x > k) ? bufA : bufB, x & 3 };
    return cq_measure(n.p[n.w]);
}
