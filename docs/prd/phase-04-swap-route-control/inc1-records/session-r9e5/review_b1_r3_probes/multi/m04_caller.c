/* m04 — AREA 1: a compound OR tree whose NON-ROOT leaf is the rail, in the
   round-2 window with the sibling BEFORE the branch. The rail's only read is
   the node's own cnot/toffoli inside `emitCondNode`. */
int ext_f(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    bool x = (y != 0);
    bool b  = cq_theta(x, 0.25);
    bool b3 = cq_theta(x, 0.9);
    if (b || q > 9) cq_phi(0.7);
    return cq_measure(q) + cq_measure(b3) + keep;
}
int main(void) { (void) slice(); return 0; }
