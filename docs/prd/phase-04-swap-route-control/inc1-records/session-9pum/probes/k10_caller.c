/* Track A.1, Rule-13 round-1 fix F-A1-1 — THE DISCRIMINATING ACCEPT CONTROL.
 *
 * `k7_caller.c` (the CONFIRMED miscompile) MINUS the round-2 sibling `b3`, so
 * the ONLY non-diagonal gate on the condition wire is the post-region S-dagger
 * `cq_theta(b, -0.25)` — which `condWireDisposition`'s DT prong legitimately
 * proves post-region and ACCEPTS, and which is the shipped S-dagger shape the
 * owner's Grover cascade writes. It ACCEPTS on the oracle (`main` 0c7380c), on
 * the pre-fix subject, and on the fixed subject. If the set difference were
 * spelled as "re-ask about every gate", this program would decline and the
 * capability would be gone; if it were spelled as the old boolean, `k7` would
 * still miscompile. It is the file that separates the two.
 * Lib TU: `review_a1_r1_probes/lib3.c`.
 */
int ext_f(int a); int opaque(void); int ext(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5; if (q > 5) y = ext_f(7);
    int z = 0; if (opaque()) z = ext(1);
    int b  = cq_theta(y, 0.25);
    if (b > 1) cq_phi(0.3);
    int b2 = cq_theta(b, -0.25);
    return cq_measure(b2) + z;
}
int main(void){ (void) slice(); return 0; }
