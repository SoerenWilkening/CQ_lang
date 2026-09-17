/* D2-N4 — MUST KEEP DECLINING. The dtzb axis. The compare `a == 5` is hoisted, and
   `t = a + i` in the body is an in-place `add` CANDIDATE on `a`'s own rail — a basis
   PERMUTATION that `WireWalk`'s forward walk deliberately does not cross, so only a
   rail closure that crosses `add`/`sub`/`xor` can see it. */
int slice(void){
    int a = 0;
    int r = 0;
    int t = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    for (int i = 0; i < 2; ++i) {
        if (a == 5) { r = cq_theta(r, 0.9); }
        t = a + i;
    }
    return cq_measure(r) + cq_measure(t);
}
int main(void){(void)slice();return 0;}
