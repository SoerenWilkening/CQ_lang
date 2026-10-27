unsigned nested_quantum_loops(unsigned x0, double th, unsigned a) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned acc = 0;
    for (unsigned i = x; i > 0; i--)          /* outer variable starts at the quantum x */
        for (unsigned j = 0; j < i; j++)      /* inner bound is the quantum outer variable */
            acc = acc * a + j;
    return cq_measure(acc);
}
