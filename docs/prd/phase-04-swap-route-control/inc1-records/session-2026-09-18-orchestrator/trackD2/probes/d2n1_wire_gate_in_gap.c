/* D2-N1 — MUST KEEP DECLINING. The compare `a == 5` is hoisted (its SSA name is
   loop-invariant) but a SIBLING chained Ry relabels `a`'s RAIL every trip, so the
   per-trip mint at BI reads a basis the source compare never read. */
int slice(void){
    int a = 0;
    int r = 0;
    int s = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    for (int i = 0; i < 2; ++i) {
        if (a == 5) { r = cq_theta(r, 0.9); }
        s = cq_theta(a, 0.1);
    }
    return cq_measure(r) + cq_measure(s);
}
int main(void){(void)slice();return 0;}
