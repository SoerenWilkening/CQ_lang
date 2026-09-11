/* w2 — H-2 at the in-place Ry arm, with a CLASSICAL opaque diamond between the
   6.5 classical-call arm's merge block and the rail region's pred, so the hcrg
   precedence alias (A.Pred == B.MergeBB) does not arise. */
int ext_f(int a);
void ext_sink(int a);
int slice(int g) {
    int q = 3;
    q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    if (g) ext_sink(keep);
    _Bool x = (y != 0);
    _Bool b  = cq_theta(x, 0.25);
    _Bool b3 = cq_theta(x, 0.9);
    int r = 7;
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    return cq_measure(r) + (int) cq_measure(b3) + keep;
}
int main(void) { (void) slice(1); return 0; }
