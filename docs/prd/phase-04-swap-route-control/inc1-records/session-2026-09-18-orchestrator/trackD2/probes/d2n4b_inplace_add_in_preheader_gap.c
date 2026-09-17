/* D2-N4b — the dtzb axis, C spelling. `u = a + 1` sits in the PREHEADER, i.e. in the
   gap `[Cond, BI)` once `clang -O1` LICM-hoists the compare, and is an in-place
   candidate on `a`'s own rail. `WireWalk`'s forward walk deliberately does not cross
   an in-place self-update, so only a rail closure that crosses `add`/`sub`/`xor` can
   see it. MUST DECLINE. (The IR ordering inside the preheader is `-O1`'s; see
   probes/d2n4b.O1.ll for what it actually emitted.) */
int slice(void){
    int a = 0;
    int r = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    int u = a + 1;
    for (int i = 0; i < 2; ++i) {
        if (a == 5) { r = cq_theta(r, 0.9); }
    }
    return cq_measure(r) + cq_measure(u);
}
int main(void){(void)slice();return 0;}
