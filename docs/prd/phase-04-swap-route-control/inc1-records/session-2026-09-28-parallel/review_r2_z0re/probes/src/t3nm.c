/* the LITERAL-base twin of t1 (bd drbq.13's base kind), spelled as a TERNARY on the angle:
   reachable from plain C with or without bd fmt3's nomerge. */
__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int r = cq_theta(6, (q > 3) ? 0.75 : 0.25);
    return cq_measure(r) + cq_measure(q);
}
int main(int argc, char **argv) { (void) argv; (void) slice(argc + 4); return 0; }
