/* PART B — one hoisted rail, TWO SIBLING loops consuming it.  anchorForConsumer
   returns loop-1's exit for the first consumer and loop-2's exit for the second;
   dagInsertPoint must land AFTER BOTH.  A discharge at loop 1's exit would
   uncompute a rail loop 2 then reads — a use-after-free of a |0> rail, i.e. a
   wrong unitary. */
int slice(void) {
    int a = 0;
    a = cq_theta(a, 0.5);
    int p = a * 3;
    int s = 0;
    for (int i = 0; i < 2; ++i) s += cq_measure((p >> i) & 1);
    for (int j = 0; j < 2; ++j) s += cq_measure((p >> (j + 4)) & 1);
    return s + cq_measure(a);
}
int main(void) { return slice(); }
