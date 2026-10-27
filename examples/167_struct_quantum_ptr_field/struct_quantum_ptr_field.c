/* Rules 21, 26: a struct whose pointer field is selected by a quantum condition (a fat pointer inside a struct);
 * dereferencing it at the quantum index n.w is one QROM load per object in the provenance (both buffers hold only
 * classical values), merged by a select on the tag. */
struct node { int *p; int w; };
int struct_quantum_ptr_field(int x0, double tx, int k, int a, int b) {
    int bufA[4] = { a, a + 1, a + 2, a + 3 };
    int bufB[4] = { b, b + 1, b + 2, b + 3 };
    int x = x0;
    cq_theta(&x, tx);
    struct node n = { (x > k) ? bufA : bufB, x & 3 };
    return cq_measure(n.p[n.w]);
}
